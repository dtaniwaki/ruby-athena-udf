# frozen_string_literal: true

require 'rubygems'
require 'simplecov'
require 'simplecov-lcov'

resultset_path = SimpleCov::ResultMerger.resultset_path
FileUtils.rm resultset_path if File.exist? resultset_path
SimpleCov.use_merging true
SimpleCov.at_exit do
  SimpleCov.command_name "fork-#{$PROCESS_ID}"
  SimpleCov.result.format!
end
SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = 'coverage/lcov.info'
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter,
]
SimpleCov.start do
  add_filter 'spec/'
  add_filter 'scripts/'
end

require 'athena_udf'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
