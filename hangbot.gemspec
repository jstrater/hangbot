# coding: utf-8
Gem::Specification.new do |spec|
   spec.name          = "hangbot"
   spec.version       = "0.1.0"
   spec.authors       = ["Josh Strater"]
   spec.email         = ["jstrater@gmail.com"]
   spec.summary       = %q{Hangman for HipChat}
   spec.description   = %q{Small Hangman game for HipChat. Uses the v2 API and webhooks.}
   spec.homepage      = "https://github.com/jstrater/hangbot"
   spec.license       = "MIT"
 
   spec.files         = `git ls-files -z`.split("\x0")
   spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
   spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
   spec.require_paths = ["lib"]
 
   spec.add_development_dependency "bundler", "~> 1.6"
   spec.add_development_dependency "rake", "~> 10.0"
   spec.add_development_dependency "guard", "~> 2.6"
   spec.add_development_dependency "guard-minitest", "~> 2.3"
 
   spec.add_runtime_dependency "httparty", "~> 0.13"
   spec.add_runtime_dependency "json", "~> 1.8"
   spec.add_runtime_dependency "configliere", "~> 0.4"
end
