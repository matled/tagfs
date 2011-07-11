require 'pathname'

class TagReader
  def initialize
    clear_cache
  end

  def tags_exact(path)
    tags = {}
    begin
      (path + ".tags").open do |fh|
        fh.each do |line|
          line.chomp!
          case line.chomp
          when /\A-/
            tags[line[1..-1]] = false
          when /\A\+/
            tags[line[1..-1]] = true
          else
            tags[line] = true
          end
        end
      end
    rescue Errno::ENOENT, Errno::EISDIR, Errno::ENOTDIR, Errno::EACCES
    end
    tags
  end

  def tags_parents(path)
    tags = {}
    path.descend do |path|
      tags.merge!(tags_exact(path))
    end
    tags
  end

  def tag_match(path, tag_spec)
    tags = tags_parents(path)

    if tag_spec.all? { |k,v| tags[k] == :both || !!tags[k] == v }
      # TODO: this will also return true if all entries are subdirectories that
      # do not match and no file exists
      return true
    end

    begin
      entries = path.entries
    rescue Errno::ENOENT, Errno::EISDIR, Errno::ENOTDIR, Errno::EACCES
      return false
    end

    entries.reject! { |e| %w(. ..).include?(e.to_s) }
    entries.any? { |entry| tag_match(path + entry, tag_spec) }
  end

  def match(path, tag_spec)
    path = Pathname.new(path) unless path.is_a?(Pathname)
    return nil unless path.exist?
    tag_match(path, tag_spec)
  end

  def clear_cache
    @cache = Hash.new { |h,v| h[v] = {} }
  end

  [:tags_parents].each do |sym|
    alias :"_#{sym}" :"#{sym}"
    class_eval <<-S
      def #{sym}(path)
        if @cache[#{sym.inspect}].has_key?(path.to_s)
          @cache[#{sym.inspect}][path.to_s]
        else
          @cache[#{sym.inspect}][path.to_s] = _#{sym}(path)
        end
      end
    S
  end
end
