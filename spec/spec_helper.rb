$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rack/test'

require 'rack-putty'

ENV['RACK_ENV'] ||= 'test'

RSpec.configure do |config|
end
