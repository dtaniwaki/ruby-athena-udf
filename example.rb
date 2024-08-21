# frozen_string_literal: true

require_relative 'lib/athena_udf'

class SimpleVarcharUDF < AthenaUDF::BaseUDF
  def self.handle_athena_record(_input_schema, _output_schema, record)
    [record[0].downcase]
  end
end
