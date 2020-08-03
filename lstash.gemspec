# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lstash/version'

Gem::Specification.new do |spec|
  spec.name          = "lstash"
  spec.version       = Lstash::VERSION
  spec.authors       = ["Klaas Jan Wierenga"]
  spec.email         = ["k.j.wierenga@gmail.com"]
  spec.description   = %q{Count or grep log messages in a specified time range from a Logstash Elasticsearch server.}
  spec.summary       = %q{The lstash gem allows you to count or grep log messages in a specific time range from a Logstash Elasticsearch server. }
  spec.homepage      = "https://github.com/kjwierenga/lstash"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = [ 'LICENSE.txt', 'README.md', 'CHANGELOG.md' ]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "timecop"

  spec.add_dependency "typhoeus"
  spec.add_dependency "elasticsearch", "~> 7"
  spec.add_dependency "hashie"
  spec.add_dependency "thor"
end
