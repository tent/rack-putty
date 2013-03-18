module Rack
  module Putty

    class Middleware
      def initialize(app, options = {})
        @app, @options = app, options
      end

      def call(env)
        response = action(env)

        # Allow middleware to cause stack to end early
        response.kind_of?(Hash) ? @app.call(env) : response
      end
    end

  end
end
