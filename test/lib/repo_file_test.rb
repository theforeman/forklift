require 'test_helper'

class TestRepoFile < Minitest::Test

  def setup
    @repo_file = Forklift::RepoFile.new(
      :name => 'Test Repo',
      :baseurl => 'file:///tmp/fake_repo'
    )
  end

  def test_repo_file
    repo = "[test-repo]\n" \
           "name=Repository for Test Repo\n" \
           "baseurl=file:///tmp/fake_repo\n" \
           "enabled=1\n" \
           "gpgcheck=0\n" \
           'protect=1'

    assert_equal @repo_file.repo_file, repo
  end

  def test_deploy
    File.expects(:open).with('/etc/yum.repos.d/test-repo.repo', 'w')

    @repo_file.deploy
  end

end
