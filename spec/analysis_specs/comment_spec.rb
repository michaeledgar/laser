require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
end