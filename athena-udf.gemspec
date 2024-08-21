# frozen_string_literal: true

require_relative 'lib/athena-udf/version'

Gem::Specification.new do |spec|
  spec.name = 'athena-udf'
  spec.version = AthenaUDF::VERSION
  spec.authors = ['Daisuke Taniwaki']
  spec.email = ['daisuketaniwaki@gmail.com']

  spec.summary = 'Ruby-version Athena UDF'
  spec.description = ''
  spec.homepage = 'https://github.com/dtaniwaki/ruby-athena-udf'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'base64'
  spec.add_dependency 'csv'
  spec.add_dependency 'red-arrow', '~> 12.0.1'
end
