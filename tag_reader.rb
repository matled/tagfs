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
          case line
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

  def merge_child_tags(hash, tags)
    tags.each do |k,v|
      next if hash[k] == :both
      if tags[k] != hash[k]
        hash[k] = :both
      else
        hash[k] = v
      end
    end
    hash
  end

  def tags_children(path)
    begin
      path = path.dirname if path.file?
      entries = path.entries
    rescue Errno::ENOENT, Errno::EISDIR, Errno::ENOTDIR, Errno::EACCES
      return {}
    end
    entries.reject! { |entry| %w(. ..).include?(entry.to_s) }
    entries = entries.select do |entry|
      begin
        (path + entry).directory?
      rescue Errno::ENOENT, Errno::EISDIR, Errno::ENOTDIR, Errno::EACCES
        false
      end
    end

    tags = tags_parents(path)

    entries.map do |entry|
      merge_child_tags(tags, tags_children(path + entry))
    end
    tags
  end

  def tag_match(path, tag_spec)
    tags = tags_children(path)
    tag_spec.all? do |k, v|
      tags[k] == :both || !!tags[k] == v
    end
  end

  def match(path, tag_spec)
    path = Pathname.new(path) unless path.is_a?(Pathname)
    return nil unless path.exist?
    tag_match(path, tag_spec)
  end

  def clear_cache
    @cache = Hash.new { |h,v| h[v] = {} }
    nil
  end

  [:tags_children, :tags_parents].each do |sym|
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
