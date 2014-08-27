# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lstash/version'

Gem::Specification.new do |spec|
  spec.name          = "lstash"
  spec.version       = Lstash::VERSION
  spec.authors       = ["Klaas Jan Wierenga"]
  spec.email         = ["k.j.wierenga@gmail.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-autotest"
  spec.add_development_dependency "autotest-standalone"
  spec.add_development_dependency "autotest-fsevent"
  spec.add_development_dependency "timecop"
end
