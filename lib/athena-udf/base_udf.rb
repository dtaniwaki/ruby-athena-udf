# frozen_string_literal: true

require 'securerandom'
require 'base64'
require 'tempfile'
require 'arrow'
require 'logger'
require_relative 'utils'

module AthenaUDF
  class BaseUDF
    extend AthenaUDF::Utils

    @@logger = Logger.new($stdout)
    @@logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'WARN').upcase)

    def self.lambda_handler(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
      incoming_type = event['@type']
      if incoming_type == 'PingRequest'
        return handle_ping(event)
      elsif incoming_type == 'UserDefinedFunctionRequest'
        return handle_udf_request(event)
      end

      raise "Unknown event type #{incoming_type} from Athena"
    end

    def self.handle_ping(event)
      {
        '@type' => 'PingResponse',
        'catalogName' => 'event',
        'queryId' => event['queryId'],
        'sourceType' => 'athena_udf',
        'capabilities' => capabilities,
      }
    end

    def self.handle_udf_request(event)
      # Cannot find a way to write Arrow::RecordBatch to a buffer directly in Ruby.

      output_schema = read_schema(Base64.decode64(event['outputSchema']['schema']))
      output_builder = Arrow::RecordBatchBuilder.new(output_schema)

      input_schema_data = Base64.decode64(event['inputRecords']['schema'])
      input_records_data = Base64.decode64(event['inputRecords']['records'])
      read_record_batches(input_schema_data, input_records_data) do |input_schema, record_batch|
        logger.info("Processing #{record_batch.size} records")
        output_builder.append_records(
          record_batch.each_record.map do |record|
            handle_athena_record(input_schema, output_schema, record)
          end,
        )
      end

      output_record_batch = output_builder.flush
      output_records_bytes = get_record_batch_bytes(output_schema, output_record_batch)

      {
        '@type' => 'UserDefinedFunctionResponse',
        'methodName' => event['methodName'],
        'records' => {
          'aId' => SecureRandom.uuid,
          'schema' => event['outputSchema']['schema'],
          'records' => Base64.strict_encode64(output_records_bytes),
        },
      }
    end

    # About capabilities: https://github.com/awslabs/aws-athena-query-federation/blob/f52d929a109099a1e7180fa242e26331137ed84c/athena-federation-sdk/src/main/java/com/amazonaws/athena/connector/lambda/handlers/FederationCapabilities.java#L29-L32
    def self.capabilities
      1
    end

    def self.handle_athena_record(input_schema, output_schema, records)
      raise NotImplementedError
    end

    def self.logger
      @@logger
    end
  end
end
