module Atlas
  module API
    module Middleware
      class RequestContextMiddleware
        CALLER_HEADER_NAME = 'HTTP_X_TELEMETRY_CALLER'.freeze
        TRANSACTION_HEADER_NAME = 'HTTP_X_TELEMETRY_TRANSACTION_ID'.freeze
        REMOTE_ADDR_KEY = 'REMOTE_ADDR'.freeze
        UNKNOWN_COMPONENT = '[Unknown Component]'.freeze

        def initialize(app)
          @app = app
        end

        def call(env)
          caller_id = env[CALLER_HEADER_NAME] || env[REMOTE_ADDR_KEY]
          transaction_id = env[TRANSACTION_HEADER_NAME] || SecureRandom.uuid

          env[:request_context] = Atlas::Service::RequestContext.new(
            time: Time.now.utc,
            component: UNKNOWN_COMPONENT,
            caller: caller_id,
            transaction_id: transaction_id,
            account_id: nil
          )

          @app.call(env)
        end
      end
    end
  end
end