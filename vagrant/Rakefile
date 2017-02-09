require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue
  puts 'Rubocop not loaded'
end

task :default => [:rubocop, :test]
