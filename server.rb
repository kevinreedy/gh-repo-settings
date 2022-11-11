# frozen_string_literal: true

require 'sinatra'
require 'dotenv/load'

get '/' do
  "Hello #{ENV['HELLO'] || 'world'}!"
end
