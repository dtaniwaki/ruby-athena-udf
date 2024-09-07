# frozen_string_literal: true

require 'benchmark'
require 'athena_udf'

Benchmark.bm 10 do |r|
  include AthenaUDF::Utils

  instance = Class.new(AthenaUDF::BaseUDF) do
    def handle_athena_record(_input_schema, _output_schema, record)
      record.to_a
    end
  end.new(event: {}, context: {})

  input_schema_1 = Arrow::Schema.new("0": :string)
  input_schema_bytes_1 = get_schema_bytes(input_schema_1)
  Arrow::Schema.new(0.upto(100).map { |n| [n.to_s, :string] }.to_h)
  input_schema_bytes_100 = get_schema_bytes(input_schema_1)

  input_table1_1 = Arrow::Table.new(input_schema_1, [['FooBar']])
  input_records_bytes_1_1 = get_record_batch_bytes(input_schema_1, input_table1_1.each_record_batch.first)
  event_1_1 = {
    '@type' => 'UserDefinedFunctionRequest',
    'inputRecords' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_1),
      'records' => Base64.strict_encode64(input_records_bytes_1_1),
    },
    'methodName' => 'lower',
    'outputSchema' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_1),
    },
    'functionType' => 'SCALAR',
  }

  r.report '1 record 1 column' do
    instance.handle_udf_request(event_1_1)
  end

  input_table100_1 = Arrow::Table.new(input_schema_1, [['FooBar']] * 100)
  input_records_bytes_100_1 = get_record_batch_bytes(input_schema_1, input_table100_1.each_record_batch.first)
  event_100 = {
    '@type' => 'UserDefinedFunctionRequest',
    'inputRecords' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_1),
      'records' => Base64.strict_encode64(input_records_bytes_100_1),
    },
    'methodName' => 'lower',
    'outputSchema' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_1),
    },
    'functionType' => 'SCALAR',
  }

  r.report '100 records 1 column' do
    instance.handle_udf_request(event_100)
  end

  input_table1_100 = Arrow::Table.new(input_schema_1, [['FooBar']])
  input_records_bytes_1_100 = get_record_batch_bytes(input_schema_1, input_table1_100.each_record_batch.first)
  event_1_100 = {
    '@type' => 'UserDefinedFunctionRequest',
    'inputRecords' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_100),
      'records' => Base64.strict_encode64(input_records_bytes_1_100),
    },
    'methodName' => 'lower',
    'outputSchema' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_100),
    },
    'functionType' => 'SCALAR',
  }

  r.report '1 record 100 column' do
    instance.handle_udf_request(event_1_100)
  end

  input_table_100_100 = Arrow::Table.new(input_schema_1, [['FooBar']])
  input_records_bytes_100_100 = get_record_batch_bytes(input_schema_1, input_table_100_100.each_record_batch.first)
  event_100_100 = {
    '@type' => 'UserDefinedFunctionRequest',
    'inputRecords' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_100),
      'records' => Base64.strict_encode64(input_records_bytes_100_100),
    },
    'methodName' => 'lower',
    'outputSchema' => {
      'schema' => Base64.strict_encode64(input_schema_bytes_100),
    },
    'functionType' => 'SCALAR',
  }

  r.report '100 record 100 column' do
    instance.handle_udf_request(event_100_100)
  end
end
