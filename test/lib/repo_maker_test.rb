require 'test_helper'

class TestRepoMaker < Minitest::Test

  def setup
    @repo_maker = Forklift::RepoMaker.new(
      :name => 'Test Repo',
      :directory => '/tmp/fake_repo'
    )
  end

  def test_create
    Forklift::RepoFile.any_instance.expects(:cleanup)
    Forklift::RepoFile.any_instance.expects(:deploy)
    @repo_maker.expects(:install_createrepo)
    @repo_maker.expects(:create_repo)

    @repo_maker.create
  end

end
