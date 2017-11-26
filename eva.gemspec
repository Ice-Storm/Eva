# -*- encoding: utf-8 -*-

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "eva/version"

Gem::Specification.new do |spec|
  spec.name          = "eva"
  spec.version       = Eva::VERSION
  spec.authors       = ["hehao"]
  spec.email         = ["wcwz020140@163.com"]

  spec.summary       = %q{dsa}
  spec.description   = %q{A Ruby/Rack web server built by libuv}
  spec.homepage      = "https://github.com/Ice-Storm/Eva"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = `git ls-files`.split($/)

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end
  #spec.bindir        = "exe"
  #spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  #spec.require_paths = ["lib"]

  spec.executables = ["eva", "evactl"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "libuv", "~> 3.2"
  spec.add_development_dependency "http-parser", "~> 1.2"
end
