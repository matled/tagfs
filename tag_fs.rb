class TagFs
  def initialize(base)
    @tag_reader = TagReader.new
    @base = Pathname.new(base)
    @base = @base.realpath unless @base.absolute?
  end

  class InvalidPath < StandardError
  end

  def parse_tag_spec(str)
    if str =~ /\A[a-zA-Z0-9_@+-]+\z/
      tags = {}
      str.scan(/(\A|[@+-])([a-zA-Z0-9_]+)/) do |pm, tag|
        if pm == "-"
          tags[tag] = false
        elsif pm == "@"
          tags.delete(tag)
        else
          tags[tag] = true
        end
      end
      tags
    else
      nil
    end
  end

  def split(str)
    tag, path = case str
    when "/"
      [nil, nil]
    when %r%\A/([^/]+)+/?\z%
      [$1, @base]
    when %r%\A/([^/]+)+/([^/].*)\z%
      [$1, @base + $2]
    else
      # should not happen
      warn "split error on #{str.inspect}"
      raise InvalidPath
    end

    if tag
      tag = parse_tag_spec(tag)
      unless tag
        raise InvalidPath
      end
    end

    [tag, path]
  end

  def readdir(requested_path)
    tag, path = split(requested_path)
    puts "TagFs#readdir(#{tag.inspect}, #{path.inspect})" if $VERBOSE
    if tag
      return nil unless @tag_reader.match(path, tag)

      begin
        entries = path.entries
      rescue Errno::ENOENT, Errno::EISDIR, Errno::ENOTDIR, Errno::EACCES
        return nil
      end
      entries.reject! { |e| %w(. ..).include?(e) }
      entries.select do |entry|
        @tag_reader.match(path + entry, tag)
      end.map(&:to_s)
    else
      @tag_reader.tags_children(@base).keys
    end
  rescue InvalidPath
    nil
  end

  def path(requested_path)
    tag, path = split(requested_path)
    puts "TagFs#path(#{tag.inspect}, #{path.inspect})" if $VERBOSE
    if tag
      return path.to_s if @tag_reader.match(path, tag)
    else
      return @base.to_s
    end
  rescue InvalidPath
    nil
  end
end
