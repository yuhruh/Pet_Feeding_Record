# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require 'date'

# set sinatra to use sessions
configure do
  enable :sessions # tell sinatra to activate sessions support
  set :session_secret, SecureRandom.hex(32) # set session_secrect, and using securerandom to create session secret
  set :erb, :escape_html => false
end

before do
  session[:headers] = %w[Date Time Category Amount Modify Delete]
  session[:table_row] ||= []
end

get '/' do
  redirect '/feedings'
end

# view all the feeding
get '/feedings' do
  @headers = session[:headers]
  @rows = session[:table_row]
  erb :feedings, layout: :layout
end

# render the new feeding form
get '/feedings/new' do
  erb :add_feeding, layout: :layout
end

# Return an error message if category and amount is invalid. Return nil if they are valid.
def error_for_check_category_and_amount(category, amount)
  (1..100).cover?(category.size) && amount.to_i.positive? && (category.to_i.to_s != category)
end

# create a new row of feeding amount, category
post '/feedings' do
  amount = params[:amount].strip
  category = params[:category].strip
  date = Time.new.strftime('%d/%m/%y') # how to validate date if allow user to input
  time = Time.new.strftime('%I:%M %p') # how to validate time if allow user to input

  if error_for_check_category_and_amount(category, amount)
    session[:table_row] << {date: date, time: time, category: category, amount: amount }
    session[:success] = 'The category and amount have been created.'
    redirect '/feedings'
  else
    session[:error] = 'Category must be between 1 and 100 characters. Or, amount should be a number'
    erb :add_feeding, layout: :layout
  end
end

# need add another page for more information?? Such as dry food brand or does the pet like it or not or more information??

# Edit an existing table cell value
get '/feedings/:id/edit' do
	idx = params[:id].to_i
	@row = session[:table_row][idx]
	erb :edit_feeding, layout: :layout
end

# Update an existing table cell value
post '/feedings/:id' do
	amount = params[:amount].strip
  category = params[:category].strip
  idx = params[:id].to_i
	@row = session[:table_row][idx]
  date = session[:table_row][idx][:date]
  time = session[:table_row][idx][:time]

  if error_for_check_category_and_amount(category, amount)
   session[:table_row][idx][:amount] = amount
   session[:table_row][idx][:category] = category
    session[:success] = "The category: #{category} and amount: #{amount} have been updated."
    redirect '/feedings'
  else
    session[:error] = 'Category must be between 1 and 100 characters.'
    erb :edit_feeding, layout: :layout
  end
end

# Delete table cell value
post '/feedings/:id/destroy' do
	idx = params[:id].to_i
	category = session[:table_row][idx][:category]
	amount = session[:table_row][idx][:amount]
	session[:table_row].delete_at(idx)
	session[:success] = "The category: #{category} and amount: #{amount} had been deleted."
	redirect '/feedings'
end