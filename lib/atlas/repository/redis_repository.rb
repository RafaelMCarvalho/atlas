# frozen_string_literal: true

module Atlas
  module Repository
    class RedisRepository
      attr_reader :redis_instance

      def initialize(redis_instance)
        @redis_instance = redis_instance
      end

      def cache(key, expiration:, &block)
        value = redis_instance.get(key)
        return value unless value.nil?
        block.call.tap do |block|
          redis_instance.set(key, block, ex: expiration, nx: true)
        end
      end
    end
  end
end
