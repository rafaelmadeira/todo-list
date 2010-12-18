#require 'app'
require ::File.expand_path('../app', __FILE__)


desc 'Migrate DataMapper database'
task :migrate do
  DataMapper.auto_migrate!
end

desc 'Set password for users'
task :password do
  User.create(:username => 'test', :password => 'test')
end
