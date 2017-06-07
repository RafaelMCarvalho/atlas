module Atlas
  module Service
    module Util
      module FormatTimestamp
        protected

        def timestamp_param(timestamp, default = Time.now.utc)
          timestamp.try(:to_time) || default
        end
      end
    end
  end
end
