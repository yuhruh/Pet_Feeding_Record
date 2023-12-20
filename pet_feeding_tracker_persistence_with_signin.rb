# frozen_string_literal: true

require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'
require 'yaml'

require 'date'

require_relative "database_persistence"

# set sinatra to use sessions
configure do
  enable :sessions # tell sinatra to activate sessions support
  set :session_secret, SecureRandom.hex(32) # set session_secrect, and using securerandom to create session secret
  set :erb, :escape_html => true
  also_reload "database_persistence.rb"
end

helpers do
  def user_signed_in?
    session.key?(:username)
  end

  def require_signed_in_user
    if !user_signed_in?
      session[:message] = "You must be signed in to do that."
      redirect '/users/signin'
    end
  end
end

def load_user_credentials
  credentials_path = File.expand_path("../users.yml", __FILE__)
  YAML.load_file( credentials_path )
end

def valid_credentials?(username, password)
  credentials = load_user_credentials
  crypted_password = BCrypt::Password.create(credentials[username])

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(crypted_password)
    bcrypt_password == password
  else
    false
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

get '/users/signin' do
  erb :signin, layout: :layout
end

post '/users/signin' do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = 'Welcome to shopping list tracker App !'
    redirect "#{session[:path]}" || '/'
  else
    session[:message] = 'Invalid credentials'
    status 422
    erb :signin, layout: :layout
  end
end


post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out.'
  redirect '/users/signin'
end

get '/' do
  redirect '/feedings'
end

# view all the feeding in table
get '/feedings' do
  @headers = @storage.get_headers
  @rows = @storage.get_table_row
  erb :feedings, layout: :layout
end

# render the new feeding form
get '/feedings/new' do
  erb :add_feeding, layout: :layout
end

# Return an error message if category is invalid 
#   - when the characters is greater than 100 and less than 1.
#   - when the catagory is fill out in number
# Return nil if they are valid.
def error_for_check_category(category)
  (1..100).cover?(category.size) && (category.to_i.to_s != category)
end

# Return an error message if the amount is positive.
def error_for_check_amount(amount)
  !amount.to_f.positive?
end

# create a new row of feeding amount, category
post '/feedings' do
  amount = params[:amount].strip
  category = params[:category].strip

 if !error_for_check_category(category)
    session[:error] = 'Category must be between 1 and 100 characters.'
    erb :add_feeding, layout: :layout
  elsif error_for_check_amount(amount)
    session[:error] = 'The amount should be a postive number'
    erb :add_feeding, layout: :layout
  else
    @storage.create_new_row(category, amount)
    session[:success] = 'The category and amount have been created.'
    redirect '/feedings'
  end
end

# Edit an existing table cell value
get '/feedings/:id/edit' do
	idx = params[:id].to_i
	@rows = @storage.get_table_row[idx]
	erb :edit_feeding, layout: :layout
end

# Update an existing table cell value
post '/feedings/:id' do
  idx = params[:id].to_i
  @row = @storage.get_table_row
  table_amount_id = @row[idx][:id]
  amount = params[:amount].strip
  category = params[:category].strip
  

   if !error_for_check_category(category)
    session[:error] = 'Category must be between 1 and 100 characters.'
    erb :edit_feeding, layout: :layout
  elsif error_for_check_amount(amount)
    session[:error] = 'The amount should be a postive number'
    erb :edit_feeding, layout: :layout  
  else
    original_category = @row[idx][:category]
    original_amount = @row[idx][:amount]
    @storage.update_table_row(table_amount_id, category, amount)
    session[:success] = "The original category: #{original_category} and amount: #{original_amount} have been updated."
    redirect '/feedings'
  end
end

# Delete specified table row
post '/feedings/:id/destroy' do
	idx = params[:id].to_i
  @row = @storage.get_table_row
  table_amount_id = @row[idx][:id]
  category = @row[idx][:category]
  amount = @row[idx][:amount]
  @storage.delete_table_row(table_amount_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The category: #{category} and amount: #{amount} have been deleted."
    redirect '/feedings'
  end
end