require "rack-putty/version"

module Rack
  module Putty
    autoload :Router, 'rack-putty/router'
    autoload :Middleware, 'rack-putty/middleware'
  end
end
