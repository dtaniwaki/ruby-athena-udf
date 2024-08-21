# frozen_string_literal: true

module AthenaUDF
  module Utils
    def read_record_batches(schema_data, record_batch_data)
      Tempfile.create do |in_f|
        in_f.write(schema_data)
        in_f.write(record_batch_data)
        in_f.flush

        Arrow::MemoryMappedInputStream.open(in_f.path) do |inp|
          reader = Arrow::RecordBatchStreamReader.new(inp)
          input_schema = reader.schema
          reader.each do |record_batch|
            yield input_schema, record_batch
          end
        end
      end
    end

    def read_schema(schema_data)
      # schema_buf = Arrow::Buffer.try_convert(schema_data)
      Tempfile.create do |f|
        f.write(schema_data)
        f.flush

        Arrow::MemoryMappedInputStream.open(f.path) do |inp|
          reader = Arrow::RecordBatchStreamReader.new(inp)
          reader.schema
        end
      end
    end

    def get_schema_bytes(schema, record_batch)
      Tempfile.create do |f|
        Arrow::FileOutputStream.open(f.path, false) do |oup|
          Arrow::RecordBatchStreamWriter.open(oup, schema) do |writer|
            writer.write_record_batch(record_batch)
          end
        end
        f.flush

        data = File.binread(f.path)
        start_index = get_record_batch_index(data)
        data.bytes[4..start_index - 5].pack('C*')
      end
    end

    def get_record_batch_bytes(schema, record_batch)
      Tempfile.create do |f|
        Arrow::FileOutputStream.open(f.path, false) do |oup|
          Arrow::RecordBatchStreamWriter.open(oup, schema) do |writer|
            writer.write_record_batch(record_batch)
          end
        end
        f.flush

        data = File.binread(f.path)
        start_index = get_record_batch_index(data)
        data.bytes[start_index..].pack('C*')
      end
    end

    def get_record_batch_index(raw)
      size = raw.bytes.size
      found_count = 0
      start_index = 0
      0.upto(size - 4).each do |i|
        has_ffff = 4.times.all? do |n|
          raw.bytes[i + n] == 255
        end
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
