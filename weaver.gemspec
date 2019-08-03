# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'weaver/version'

Gem::Specification.new do |spec|
  unless spec.respond_to?(:metadata)
    # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host',
    # or delete this section to allow pushing this gem to any host.
    raise <<-ERR
      RubyGems 2.0 or newer is required to protect against public gem pushes.
    ERR
  end

  spec.name          = 'weaver'
  spec.version       = Weaver::VERSION
  spec.authors       = ['David Siaw']
  spec.email         = ['davidsiaw@gmail.com']

  spec.summary       = 'Website generator'
  spec.description   = 'Site generator with a simple DSL'
  spec.homepage      = 'https://davidsiaw.github.io/weaver-docs/'
  spec.license       = 'MIT'

  spec.files         = Dir['**/*']
  spec.test_files    = Dir['{test,spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'optimist'
  spec.add_dependency 'sinatra', '~> 2.0.3'

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
end
