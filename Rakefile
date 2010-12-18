requre 'app'

desc 'Migrate DataMapper database'
task :migrate do
  DataMapper.auto_migrate!
end

desc 'Set password for users'
task :password do
  User.create(:name => 'wtf', :password => 'test')
end
