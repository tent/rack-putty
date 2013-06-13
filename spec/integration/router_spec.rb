require 'spec_helper'
require 'json'

describe Rack::Putty::Router do
  include Rack::Test::Methods

  class SerializeResponse
    def self.call(env)
      headers = { 'Content-Type' => 'text/plain' }.merge(env['response_headers'] || {})
      if env['response']
        [200, headers, [serialize_response(headers, env['response'])]]
      else
        [404, headers, ['Not Found']]
      end
    end

    def self.serialize_response(headers, response)
      if headers['Content-Type'] =~ /json/
        response.to_json
      end
    end
  end

  class TestMiddleware < Rack::Putty::Middleware
    def action(env)
      env['response'] ||= {}
      env['response']['params'] = env['params']
      env['response_headers'] = { 'Content-Type' => 'application/json' }
      env
    end
  end

  class OtherTestMiddleware < Rack::Putty::Middleware
    def action(env)
      env['response'] ||= {}
      env['response'][@options[:key]] = @options[:val]
      env
    end
  end

  class TestMiddlewarePrematureResponse < Rack::Putty::Middleware
    def action(env)
      [200, { 'Content-Type' => 'text/plain' }, ['Premature-Response']]
    end
  end

  class TestMountedApp
    include Rack::Putty::Router

    stack_base SerializeResponse
    middleware OtherTestMiddleware, :key => 'foo', :val => 'bar'
    middleware OtherTestMiddleware, :key => 'biz', :val => 'baz'

    get '/chunky/:bacon' do |b|
      b.use TestMiddleware
    end
  end

  class PrefixMountedApp
    def initialize(app)
      @app = app
    end

    def call(env)
      myprefix = '/prefix'

      if env['PATH_INFO'].start_with?(myprefix)
        env['SCRIPT_NAME'] = env['SCRIPT_NAME'][0..-2] if env['SCRIPT_NAME'].end_with?('/') # strip trailing slash
        env['SCRIPT_NAME'] += myprefix

        env['PATH_INFO'].sub! myprefix, ''
        @app.call(env)
      end
    end
  end

  class TestApp
    include Rack::Putty::Router

    stack_base SerializeResponse

    get '/foo/:bar' do |b|
      b.use TestMiddleware
    end

    get '/premature/response' do |b|
      b.use TestMiddlewarePrematureResponse
      b.use TestMiddleware
    end

    post %r{^/foo/([^/]+)/bar} do |b|
      b.use TestMiddleware
    end

    mount TestMountedApp
  end

  def app
    _app = TestApp.new
    proc do |env|
      env['REQUEST_URI'] = [env['PATH_INFO'], env['QUERY_STRING']].join('?')
      _app.call(env)
    end
  end

  let(:env) { {} }

  context "as a mounted app with a prefix" do
    let(:app) do
      _app = TestApp.new
      PrefixMountedApp.new(proc { |env|
        env['REQUEST_URI'] = [env['PATH_INFO'], env['QUERY_STRING']].join('?')
        _app.call(env)
      })
    end

    it "still matches the path name" do
      get '/prefix/foo/baz', {}, env
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['params']['bar']).to eq('baz')
    end
  end

  it "should extract params" do
    get '/foo/baz', nil, env
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['params']['bar']).to eq('baz')
  end

  it "should merge both sets of params" do
    post '/foo/baz/bar?chunky=bacon', {}, env
    expect(last_response.status).to eq(200)
    actual_body = JSON.parse(last_response.body)
    expect(actual_body['params']['chunky']).to eq('bacon')
    expect(actual_body['params']['captures']).to include('baz')
  end

  it "should work with mount" do
    get '/chunky/crunch', {}, env
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['params']['bacon']).to eq('crunch')
    expect(body['foo']).to eq('bar')
    expect(body['biz']).to eq('baz')
  end

  it "should allow middleware to prematurely respond" do
    get '/premature/response', {}, env
    expect(last_response.body).to eq('Premature-Response')
  end
end
