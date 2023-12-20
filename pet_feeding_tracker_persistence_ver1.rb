# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require 'date'

require_relative "database_persistence"

# set sinatra to use sessions
configure do
  enable :sessions # tell sinatra to activate sessions support
  set :session_secret, SecureRandom.hex(32) # set session_secrect, and using securerandom to create session secret
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
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