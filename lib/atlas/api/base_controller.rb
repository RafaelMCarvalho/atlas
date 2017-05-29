module Atlas
  module API
    module BaseController
      extend Dry::Configurable
      def self.included(base)
        base.class_eval do
          include Hanami::Action
          extend Atlas::API::Context::DSL
          use Rack::Deflater
        end
      end
      setting :serializers_namespace

      MODULE_SEPARATOR = '::'.freeze

      ERROR_CODE_TO_HTTP_STATUS = {
        Atlas::Enum::ErrorCodes::NONE => 200,
        Atlas::Enum::ErrorCodes::AUTHENTICATION_ERROR => 401,
        Atlas::Enum::ErrorCodes::PERMISSION_ERROR => 403
      }.freeze

      def render(service_response)
        data = service_response.data
        code = service_response.code
        self.body = response_body(service_response).to_json
        self.status = ERROR_CODE_TO_HTTP_STATUS[code] || 400
        headers.merge!(response_headers(data))
      end

      def render_pdf(service_response)
        data = service_response.data
        code = service_response.code
        self.body = data
        self.status = ERROR_CODE_TO_HTTP_STATUS[code] || 400
        self.headers['Content-Type'] = 'application/pdf'
      end

      def render_xml(service_response)
        data = service_response.data
        code = service_response.code
        self.body = data
        self.status = ERROR_CODE_TO_HTTP_STATUS[code] || 400
        self.headers['Content-Type'] = 'application/xml'
      end

      private

      def response_body(service_response)
        code = service_response.code
        if service_response.data.is_a?(Atlas::Service::Mechanism::Pagination::QueryResult)
          data = service_response.data.results
        elsif !service_response.success?
          data = { code: code, message: service_response.message, errors: service_response.data }
        else
          data = service_response.data
        end
        serializer = serialize_data(data)
        serializer.new(data)
      end

      def serialize_data(data)
        return API::Serializer::DummySerializer if data.empty? || data.is_a?(Hash)
        return serialize_data(data.first) if data.is_a?(Array)
        entity = data.class.name.split(MODULE_SEPARATOR).last
        serializer = BaseController.config.serializers_namespace.const_get("#{entity}Serializer".to_sym)
        serializer
      rescue NameError
        API::Serializer::DummySerializer
      end

      def response_headers(data)
        base = { 'Content-Type' => 'application/json' }
        return base unless data.is_a?(Atlas::Service::Mechanism::Pagination::QueryResult)
        base.merge('Total' => data.total.to_s, 'Per-Page' => data.per_page.to_s)
      end
    end
  end
end
