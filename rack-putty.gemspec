# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack-putty/version'

Gem::Specification.new do |gem|
  gem.name          = "rack-putty"
  gem.version       = Rack::Putty::VERSION
  gem.authors       = ["Jonathan Rudenberg", "Jesse Stuart"]
  gem.email         = ["jonathan@titanous.com", "jesse@jessestuart.ca"]
  gem.description   = %q{Simple web framework built on rack for mapping sinatra-like routes to middleware stacks.}
  gem.summary       = %q{Simple web framework built on rack.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'rack-mount', '~> 0.8.3'

  gem.add_development_dependency 'rack-test', '~> 0.6.1'
  gem.add_development_dependency 'rspec', '~> 2.11'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
end
