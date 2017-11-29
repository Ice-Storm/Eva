# -*- encoding: utf-8 -*-

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "eva/version"

Gem::Specification.new do |spec|
  spec.name          = "eva"
  spec.version       = Eva::VERSION
  spec.authors       = ["hehao"]
  spec.email         = ["wcwz020140@163.com"]

  spec.summary       = %q{Eva is a fast Ruby/Rack web server}
  spec.description   = %q{Eva is a fast event loop Ruby/Rack web server build by libuv}
  spec.homepage      = "https://github.com/Ice-Storm/Eva"
  spec.license       = "MIT"

  spec.files = `git ls-files`.split($/)

  spec.executables = ["eva", "evactl"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "libuv", "~> 3.2"
  spec.add_development_dependency "http-parser", "~> 1.2"
end
