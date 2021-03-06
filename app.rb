require 'rubygems'
require 'sinatra'
require 'pg' if :environment == :production
require 'dm-core'
require 'dm-postgres-adapter' if :environment == :production
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'
require 'bcrypt'
require 'rack-flash'

# Enable sessions and use Rack Flash
enable :sessions
use Rack::Flash

# Some helpers that help you
helpers do

  # Allows use of "h" to escape HTML
  include Rack::Utils
  alias_method :h, :escape_html

  # Check to see if a user is logged in
  def logged_in?
    if request.cookies['userid']
      true
    else
      false
    end
  end

  # Add this to the top of a route to make it accessible only to logged in users
  def authorize!
    redirect '/' unless logged_in?
  end

  # Get the logged in user's ID
  def get_userid
    request.cookies['userid']
  end

  # Set the logged in user's ID (logging them in)
  def set_userid(id)
    response.set_cookie('userid', id)
  end

end

# ==============
# Database Setup
# ==============

DataMapper::Logger.new($stdout, :debug)
# Set up the database connection
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/my.db")

# A basic user database model
class User

  include DataMapper::Resource

  property :id,         Serial
  property :username,   String,     :required => true, :unique => true
  property :password,   BCryptHash, :required => true, :length => 255
  property :created_at, DateTime

  has n, :tasks
end

class Task
  include DataMapper::Resource

  property :id,           Serial
  property :body,         Text,     :required => true
  property :release_date, Date
  property :created_at,   DateTime
  property :status,       Boolean,  :default => false

  belongs_to :user
end
# Finalize the database and create the database tables if needed
DataMapper.finalize
DataMapper.auto_upgrade!

# ======
# Routes
# ======

# Show an index page
get '/' do
  if logged_in?
    erb :todo
  else
    redirect '/login'
  end
end

# Show a login form or log the user out
get '/login/?' do
  unless logged_in?
    erb :login
  else
    flash[:notice] = 'You have been logged out.'
    response.delete_cookie('userid')
    redirect '/'
  end
end

# Log the user in
post '/login/?' do
  user = User.first(:username => params[:username])
  if user
    if user.password == params[:password]
      set_userid(user.id)
      flash[:notice] = 'You are now logged in.'
      redirect '/'
    else
      flash[:notice] = 'Incorrect password.'
      redirect '/login'
    end
  else
    flash[:notice] = 'Incorrect username.'
    redirect '/login'
  end
end

post '/task/new' do
  if logged_in?
    user = User.first(:id => get_userid)
    if params[:release_date].empty?
      puts params
      task = Task.create(:user_id => user.id, :body => params[:body], :release_date => '3000-10-10', :status => params[:status])
    else
      puts "rprprp"
      task = Task.create(:user_id => user.id, :body => params[:body], :release_date => params[:release_date], :status => params[:status])
    end
    #add false
  else
    redirect '/login'
  end
end

post '/task/update' do
  if logged_in?
    user = User.first(:id => get_userid)
    task = user.tasks.first(:id => params[:id])
    task.update( :status => params[:status]) unless task.nil?
  else
    redirect '/login'
  end
end

post '/task/delete' do
  if logged_in?
    user = User.first(:id => get_userid)
    task = user.tasks.first(:id => params[:id])
    task.destroy unless task.nil?
  else
    redirect '/login'
  end
end

# Catch any URL that wasn't already handled and show a 404 page
get '/*' do
  erb :notfound
end
