# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'

begin
  gem 'rdoc'
  require 'rdoc/task'
rescue Gem::LoadError
  require 'rake/rdoctask'
end

require 'tasks/rails'

