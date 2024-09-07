# frozen_string_literal: true

require 'json'

RSpec.describe AthenaUDF::BaseUDF do
  include AthenaUDF::Utils

  let(:klass) do
    Class.new(AthenaUDF::BaseUDF) do
      def handle_athena_record(_input_schema, _output_schema, record)
        [record[0].downcase]
      end
    end
  end
  before { allow(SecureRandom).to receive(:uuid).and_return('ec15fd87-f1e6-40fd-b63e-c5107add32d4') }

  context('PingRequest') do
    it 'returns a response successfully' do
      event = {
        '@type' => 'PingRequest',
        'queryId' => 'test',
      }
      context = {}
      expected = {
        '@type' => 'PingResponse',
        'capabilities' => 1,
        'catalogName' => 'event',
        'queryId' => 'test',
        'sourceType' => 'athena_udf',
      }
      expect(klass.lambda_handler(event:, context:)).to eq(expected)
    end
  end
  context('UserDefinedFunctionRequest') do
    it 'returns a response successfully' do
      input_schema = Arrow::Schema.new(s: :string, x: :int32)
      input_table = Arrow::Table.new(input_schema, [['FooBar', 1], ['Xyz', 2]])
      input_schema_bytes = get_schema_bytes(input_schema)
      input_records_bytes = get_record_batch_bytes(input_schema, input_table.each_record_batch.first)

      output_schema = Arrow::Schema.new(s: :string)
      output_table = Arrow::Table.new(output_schema, [['foobar'], ['xyz']])
      output_schema_bytes = get_schema_bytes(output_schema)
      output_records_bytes = get_record_batch_bytes(output_schema, output_table.each_record_batch.first)

      event = {
        '@type' => 'UserDefinedFunctionRequest',
        'inputRecords' => {
          'schema' => Base64.strict_encode64(input_schema_bytes),
          'records' => Base64.strict_encode64(input_records_bytes),
        },
        'methodName' => 'lower',
        'outputSchema' => {
          'schema' => Base64.strict_encode64(output_schema_bytes),
        },
        'functionType' => 'SCALAR',
      }
      context = {}
      expected = {
        '@type' => 'UserDefinedFunctionResponse',
        'methodName' => 'lower',
        'records' => {
          'aId' => 'ec15fd87-f1e6-40fd-b63e-c5107add32d4',
          'records' => Base64.strict_encode64(output_records_bytes),
          'schema' => Base64.strict_encode64(output_schema_bytes),
        },
      }
      expect(klass.lambda_handler(event:, context:)).to eq(expected)
    end
  end
  context('Unknown event type') do
    it 'raises an exception' do
      event = {
        '@type' => 'Foo',
      }
      context = {}
      expect do
        klass.lambda_handler(event:, context:)
      end.to raise_error(RuntimeError, 'Unknown event type Foo from Athena')
    end
  end
end
