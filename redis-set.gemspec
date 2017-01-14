# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/set'

Gem::Specification.new do |spec|
  spec.name          = "redis-set"
  spec.version       = Redis::Set::VERSION
  spec.authors       = ["Misha Conway"]
  spec.email         = ["mishaAconway@gmail.com"]

  spec.summary       = %q{Lightweight wrapper over redis sets.}
  spec.description   = %q{Lightweight wrapper over redis sets.}
  spec.homepage      = "https://github.com/MishaConway/ruby-redis-set"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency 'redis'
end
