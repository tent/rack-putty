require 'rack/mount'

class Rack::Mount::RouteSet
  def merge_routes(routes)
    routes.each { |r| merge_route(r) }
    rehash
  end

  def merge_route(route)
    @routes << route

    @recognition_key_analyzer << route.conditions

    @named_routes[route.name] = route if route.name
    @generation_route_keys << route.generation_keys

    expire!
    route
  end
end

module Rack
  module Putty

    module Router
      MissingStackBaseError = Class.new(StandardError)

      require 'rack-putty/router/extract_params'

      def self.included(base)
        base.extend(ClassMethods)
        base.routes.rehash
      end

      def call(env)
        self.class.routes.call(env)
      end

      module ClassMethods
        def stack_base(klass)
          @stack_base = klass
        end

        def middleware(klass, *args)
          @middleware ||= []
          @middleware << [klass, args]
        end

        def mount(klass)
          routes.merge_routes klass.routes.instance_variable_get("@routes")
        end

        def routes
          @routes ||= Rack::Mount::RouteSet.new
        end

        #### This section heavily "inspired" by sinatra

        # Defining a `GET` handler also automatically defines
        # a `HEAD` handler.
        def get(path, opts={}, &block)
          route('GET', path, opts, &block)
          route('HEAD', path, opts, &block)
        end

        def put(path, opts={}, &bk)     route 'PUT',     path, opts, &bk end
        def post(path, opts={}, &bk)    route 'POST',    path, opts, &bk end
        def patch(path, opts={}, &bk)   route 'PATCH',   path, opts, &bk end
        def delete(path, opts={}, &bk)  route 'DELETE',  path, opts, &bk end
        def head(path, opts={}, &bk)    route 'HEAD',    path, opts, &bk end
        def options(path, opts={}, &bk) route 'OPTIONS', path, opts, &bk end

        def match(path, opts={}, &bk)
          get(path, opts, &bk)
          put(path, opts, &bk)
          post(path, opts, &bk)
          patch(path, opts, &bk)
          delete(path, opts, &bk)
          options(path, opts, &bk)
        end

        private

        def route(verb, path, options={}, &block)
          path, params = compile_path(path)

          return if route_exists?(verb, path)

          unless @stack_base
            raise MissingStackBaseError.new("You need to call `stack_base` with a base app class to be passed to Rack::Builder.new.")
          end

          # Remove ContentLength and Chunked middlewares from default stack so we can put HEAD before them...
          Rack::Server.middleware['development'] = [[Rack::ShowExceptions], [Rack::Lint], Rack::Server.logging_middleware]
          Rack::Server.middleware['deployment'] = [Rack::Server.logging_middleware]

          builder = Rack::Builder.new(@stack_base)

          # ...and here it is
          builder.use(Rack::Head)
          builder.use(Rack::Chunked)
          builder.use(Rack::ContentLength)

          builder.use(ExtractParams, path, params)

          (@middleware || []).each do |i|
            klass, args = i
            builder.use(klass, *args)
          end

          block.call(builder)

          routes.add_route(builder.to_app, :request_method => verb, :path_info => path)
          routes.rehash
        end

        def route_exists?(verb, path)
          @added_routes ||= []
          return true if @added_routes.include?("#{verb}#{path}")
          @added_routes << "#{verb}#{path}"
          false
        end

        def compile_path(path)
          keys = []
          if path.respond_to? :to_str
            ignore = ""
            pattern = path.to_str.gsub(/[^\?\%\\\/\:\*\w]/) do |c|
              ignore << escaped(c).join if c.match(/[\.@]/)
              encoded(c)
            end
            pattern.gsub!(/((:\w+)|\*)/) do |match|
              if match == "*"
                keys << 'splat'
                "(.*?)"
              else
                keys << $2[1..-1]
                "([^#{ignore}/?#]+)"
              end
            end
            [/\A#{pattern}\z/, keys]
          elsif path.respond_to?(:keys) && path.respond_to?(:match)
            [path, path.keys]
          elsif path.respond_to?(:names) && path.respond_to?(:match)
            [path, path.names]
          elsif path.respond_to? :match
            [path, keys]
          else
            raise TypeError, path
          end
        end

        def encoded(char)
          enc = URI.escape(char)
          enc = "(?:#{escaped(char, enc).join('|')})" if enc == char
          enc = "(?:#{enc}|#{encoded('+')})" if char == " "
          enc
        end

        def escaped(char, enc = URI.escape(char))
          [Regexp.escape(enc), URI.escape(char, /./)]
        end
      end
    end

  end
end
