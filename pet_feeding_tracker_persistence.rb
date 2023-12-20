# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require 'date'

#require_relative "database_persistence"

# set sinatra to use sessions
configure do
  enable :sessions # tell sinatra to activate sessions support
  set :session_secret, SecureRandom.hex(32) # set session_secrect, and using securerandom to create session secret
  set :erb, escape_html: false
end

before do
  @storage = DatabasePersistence.new(session)
end

class DatabasePersistence
  def initialize(session)
    @session = session
    #@db = PG.connect(dbname: "amount")
    @session[:headers] = %w[Date Time Category Amount Modify Delete]
    @session[:table_row] ||= []
  end

  def get_headers
    @session[:headers]
  end

  def get_table_row
    @session[:table_row]
  end

  def create_new_row(category, amount)
    date = Time.new.strftime('%y/%m/%d') # how to validate date if allow user to input
    time = Time.new.strftime('%I:%M %p') # how to validate time if allow user to input
    @session[:table_row] << {date: date, time: time, category: category, amount: amount }
  end
end

get '/' do
  redirect '/feedings'
end

# view all the feeding
get '/feedings' do
  @headers = @storage.get_headers
  @rows = @storage.get_table_row
  erb :feedings, layout: :layout
end

# render the new feeding form
get '/feedings/new' do
  erb :add_feeding, layout: :layout
end

# Return an error message if category and amount is invalid. Return nil if they are valid.
def error_for_check_category(category)
  (1..100).cover?(category.size) && (category.to_i.to_s != category)
end

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

# need add another page for more information?? Such as dry food brand or does the pet like it or not or more information??

# Edit an existing table cell value
get '/feedings/:id/edit' do
	idx = params[:id].to_i
	@rows = @storage.get_table_row[idx]
	erb :edit_feeding, layout: :layout
end

# Update an existing table cell value
post '/feedings/:id' do
	amount = params[:amount].strip
  category = params[:category].strip
  idx = params[:id].to_i
	@row = @storage.get_table_row[idx]
  date = @row[:date]
  time = @row[:time]

  if !error_for_check_category(category)
    session[:error] = 'Category must be between 1 and 100 characters.'
    erb :edit_feeding, layout: :layout
  elsif error_for_check_amount(amount)
    session[:error] = 'The amount should be a postive number'
    erb :edit_feeding, layout: :layout  
  else
    @row[:amount] = amount
    @row[:category] = category
    session[:success] = "The category: #{category} and amount: #{amount} have been updated."
    redirect '/feedings'
  end
end

# Delete table cell value
post '/feedings/:id/destroy' do
	idx = params[:id].to_i
  @row = session[:table_row]
	category = @row[idx][:category]
	amount = @row[idx][:amount]
	@row.delete_at(idx)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The category: #{category} and amount: #{amount} have been deleted."
    redirect '/feedings'
  end
end