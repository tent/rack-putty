# Rack::Putty

Simple web framework built on rack for mapping sinatra-like routes to middleware stacks.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-putty'

## Usage

```ruby
  require 'rack-putty'

  module YourApp
    class Router
      include Rack::Putty::Router

      class SerializeResponse
        def self.call(env)
          headers = { 'Content-Type' => 'text/plain' }.merge(env.response_headers || {})
          if env.response
            [200, headers, [env.response]]
          else
            [404, headers, ['Not Found']]
          end
        end
      end

      class CorsHeaders
        def initialize(app)
          @app = app
        end

        def call(env)
          status, headers, body = @app.call(env)
          headers.merge!(
            'Access-Control-Allow-Origin' => '*',
          ) if env['HTTP_ORIGIN']
          [status, headers, body]
        end
      end

      stack_base SerializeResponse
      middleware CorsHeaders

      class HelloWorld < Rack::Putty::Middleware
        def action(env)
          env.response = 'Hello World'
          env
        end
      end

      get '/' do |builder|
        builder.use HelloWorld
      end
    end
  end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
