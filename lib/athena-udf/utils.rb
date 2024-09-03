# frozen_string_literal: true

module AthenaUDF
  module Utils
    def read_record_batches(schema_data, record_batch_data)
      buffer = Arrow::ResizableBuffer.new(schema_data.bytes.size + record_batch_data.bytes.size)
      Arrow::BufferOutputStream.open(buffer) do |output|
        output.write(schema_data)
        output.write(record_batch_data)

        Arrow::BufferInputStream.open(buffer) do |input|
          reader = Arrow::RecordBatchStreamReader.new(input)
          input_schema = reader.schema
          reader.each do |record_batch|
            yield input_schema, record_batch
          end
        end
      end
    end

    def read_schema(schema_data)
      buffer = Arrow::ResizableBuffer.new(schema_data.bytes.size)
      Arrow::BufferOutputStream.open(buffer) do |output|
        output.write(schema_data)

        Arrow::BufferInputStream.open(buffer) do |input|
          reader = Arrow::RecordBatchStreamReader.new(input)
          reader.schema
        end
      end
    end

    def get_schema_bytes(schema, record_batch)
      buffer = Arrow::ResizableBuffer.new(0)
      Arrow::BufferOutputStream.open(buffer) do |output|
        Arrow::RecordBatchStreamWriter.open(output, schema) do |writer|
          writer.write_record_batch(record_batch)
        end

        bytes = buffer.data.to_s
        start_index = get_record_batch_index(bytes)
        bytes[4..start_index - 5]
      end
    end

    def get_record_batch_bytes(schema, record_batch)
      buffer = Arrow::ResizableBuffer.new(0)
      Arrow::BufferOutputStream.open(buffer) do |output|
        Arrow::RecordBatchStreamWriter.open(output, schema) do |writer|
          writer.write_record_batch(record_batch)
        end

        bytes = buffer.data.to_s
        start_index = get_record_batch_index(bytes)
        bytes[start_index..]
      end
    end

    def get_record_batch_index(bytes)
      size = bytes.size
      found_count = 0
      start_index = 0
      0.upto(size - 4).each do |i|
        has_ffff = bytes.slice(i, 4) == [255, 255, 255, 255]
        found_count += 1 if has_ffff
        if found_count == 2
          start_index = i + 4
          break
        end
      end

      start_index
    end
  end
end
