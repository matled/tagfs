require './ext/fuse'

module Fuse
  def self.path(path)
    @obj.path(path)
  end

  def self.readdir(path)
    @obj.readdir(path)
  end

  def self.obj
    @obj
  end

  def self.obj=(obj)
    @obj = obj
  end
end
