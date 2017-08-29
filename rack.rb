require 'rubygems'
require 'rack'

require_relative './lib/rack/handler/eva'

# Rack::Handler::Eva.run proc {|env| [200, {"Content-Type" => "text/html"}, "<h1>Hello!!!</h1>"]}

require 'sinatra'
class MyApp < Sinatra::Base

  configure { set :server, :eva }

  include FileUtils::Verbose

  get '/' do
    #sleep 1
    'ext_fun!!!!!'
  end

  post '/' do
    'ext_fun!!!!!'
  end


  get '/a' do
    'ext_funa'
  end

  post '/a' do
    p params
    'ddddd'
  end
end

#MyApp.run!
