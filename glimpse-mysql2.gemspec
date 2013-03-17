# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'glimpse-mysql2/version'

Gem::Specification.new do |gem|
  gem.name          = 'glimpse-mysql2'
  gem.version       = Glimpse::Mysql2::VERSION
  gem.authors       = ['Garrett Bjerkhoel']
  gem.email         = ['me@garrettbjerkhoel.com']
  gem.description   = %q{Provide a glimpse into the MySQL queries made during your application's requests.}
  gem.summary       = %q{Provide a glimpse into the MySQL queries made during your application's requests.}
  gem.homepage      = 'https://github.com/dewski/glimpse-mysql2'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'glimpse'
  gem.add_dependency 'mysql2'
  gem.add_dependency 'atomic', '>= 1.0.0'
end
