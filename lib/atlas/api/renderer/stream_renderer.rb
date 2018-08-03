# frozen_string_literal: true

module Atlas
  module API
    module Renderer
      class StreamRenderer < JsonRenderer
        def headers
          super.merge('Content-Encoding' => 'gzip') if service_response.success?
        end

        def body
          return error_from(service_response).to_json unless service_response.success?

          data = body_data
          return data unless data.is_a?(Enumerable)
          lazy_data = data.lazy

          element = nil

          Enumerator.new do |yielder|
            stream = Atlas::Util::GzipYieldStream.new(yielder)
            stream.write("[\n")

            loop do
              element = lazy_data.next
              puts "ELEMENT: #{element}"
              stream.write(serializer_instance_to(data).to_json)
              stream.write(",\n")
            end

          rescue StopIteration
            stream.write(serializer_instance_to(data).to_json) if element
            stream.write("\n]")
            stream.close
          end
        end
      end
    end
  end
end
