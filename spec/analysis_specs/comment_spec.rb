require_relative 'spec_helper'

describe Laser::Comment do
  before do
    body = <<-EOF
##
# Returns a repository object for the given path. Should respond to the standard repository
# API to the best of its ability, and raise a CapabilityError if asked to do something it
# cannot do from the API.
#
# @param [AmpConfig] config the configuration of the current environment, loaded from
#    appropriate configuration files
# @param [String] path the path/URL in which to open the repository.
# @param [Boolean] create should a repository be created in the given directory/URL?
# @return [AbstractLocalRepository] the repository for the given URL
# @example
#    Repo.pick('abc/def') do |foo|
#      File.open(foo + '/.hg/hgrc')
#    end
EOF
    @comment = Laser::Comment.new(body, 2, 4)
    normal_annotated_body = <<-EOF
##
# Returns a repository object for the given path. Should respond to the standard repository
# cannot do from the API.
#
# config: AmpConfig
# path: String=
# create: TrueClass | FalseClass
# return: AbstractLocalRepository
# @example
#    Repo.pick('abc/def') do |foo|
#      File.open(foo + '/.hg/hgrc')
#    end
EOF
    @annotated_comment = Laser::Comment.new(normal_annotated_body, 8, 12)
  end
  
  describe '#location' do
    it 'packs up the line and column' do
      @comment.location.should == [2, 4]
    end
  end
  
  describe '#features' do
    it 'should extract features based on whether line breaks are followed by many spaces' do
      @comment.features.should == [
        'Returns a repository object for the given path. Should respond to the standard repository',
        'API to the best of its ability, and raise a CapabilityError if asked to do something it',
        'cannot do from the API.',
        "@param [AmpConfig] config the configuration of the current environment, loaded from\n"+
        "   appropriate configuration files",
        '@param [String] path the path/URL in which to open the repository.',
        '@param [Boolean] create should a repository be created in the given directory/URL?',
        '@return [AbstractLocalRepository] the repository for the given URL',
        "@example\n"+
        "   Repo.pick('abc/def') do |foo|\n"+
        "     File.open(foo + '/.hg/hgrc')\n"+
        "   end"
        ]
    end
  end
  
  describe '#annotations' do
    it 'should extract annotations and parse them' do
      notes = @annotated_comment.annotations
      parts = notes.map(&:name).zip notes.map(&:type)
      parts.should == [
        ['config', Types::ClassType.new('AmpConfig', :covariant)],
        ['path', Types::ClassType.new('String', :invariant)],
        ['create', Types::UnionType.new([
          Types::ClassType.new('TrueClass', :covariant),
          Types::ClassType.new('FalseClass', :covariant)])],
        ['return', Types::ClassType.new('AbstractLocalRepository', :covariant)]
      ]
    end
  end
  
  describe '#annotation_map' do
    it 'should extract annotations and convert them to a hash keyed by name' do
      map = @annotated_comment.annotation_map.to_a
      parts = map.map { |name, note| [name, note[0].name, note[0].type] }
      parts.should == [
        ['config', 'config', Types::ClassType.new('AmpConfig', :covariant)],
        ['path', 'path', Types::ClassType.new('String', :invariant)],
        ['create', 'create', Types::UnionType.new([
          Types::ClassType.new('TrueClass', :covariant),
          Types::ClassType.new('FalseClass', :covariant)])],
        ['return', 'return', Types::ClassType.new('AbstractLocalRepository', :covariant)]
      ]
    end
  end
end
