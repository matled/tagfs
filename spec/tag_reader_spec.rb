require 'spec_helper'

describe TagReader do
  before(:all) do
    @tagfs = TagReader.new
    @base = Pathname.new(Dir.pwd + "/testfs")
  end

  def match(path, spec)
    @tagfs.match(@base + path, spec)
  end

  it "should tag one directory correctly" do
    match("a", { "foo" => true }).should be_true
    match("a", { "bar" => true }).should_not be_true
  end

  it "should inherit tags in subdirectories" do
    match("a/sub", { "foo" => true }).should be_true
    match("a/sub", { "bar" => true }).should_not be_true
  end

  it "should allow multiple tags" do
    match("b", { "foo" => true }).should be_true
    match("b", { "bar" => true }).should be_true
  end

  it "should should inherit tags from children" do
    match("c", { "bar" => true }).should be_true
    match("c", { "foo" => true }).should be_true
    match("c", { "foobar" => true }).should be_true
  end

  it "should tag files" do
    match("d", { "foo" => true }).should be_true
    match("d/file", { "foo" => true }).should be_true
  end

  it "should handle errors" do
    match("d/non-existent", { "foo" => true }).should_not be_true
    match("d/file/foobar", { "foo" => true }).should_not be_true
  end

  it "should allow + as prefix" do
    match("e", { "foo" => true }).should be_true
  end

  it "should allow to remove tags" do
    # e has both +foo and -foo as this directory has foo tag and a
    # subdirectory doesn't have it
    match("e", { "foo" => true }).should be_true
    match("e", { "foo" => false }).should be_true
    # no-foo does not have foo tag
    match("e/no-foo", { "foo" => true }).should_not be_true
    match("e/no-foo", { "foo" => false }).should be_true
    # foo has foo tag
    match("e/foo", { "foo" => true }).should be_true
    match("e/foo", { "foo" => false }).should_not be_true
  end

  it "should combine tags correctly" do
    # f   => t1, t2
    # f/a => t1, t3
    # f/b => t1, t2, t4

    # f/a matches
    match("f", { "t1" => true, "t2" => false }).should be_true
    # f matches
    match("f", { "t1" => true, "t2" => true }).should be_true
    # f/b matches
    match("f", { "t1" => true, "t2" => true, "t3" => false, "t4" => true }).should be_true
    # no directory matches
    match("f", { "t1" => true, "t5" => true }).should_not be_true
    # no directory matches
    match("f", { "t1" => true, "t2" => true, "t3" => true, "t4" => true }).should_not be_true
  end
end
