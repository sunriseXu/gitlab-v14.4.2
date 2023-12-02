# frozen_string_literal: true

module Gitlab
  module Instrumentation
    # Aggregates Redis measurements from different request storage sources.
    class Redis
      # Actioncable has it's separate instrumentation, but isn't configurable
      # in the same way as all the other instances using a class.
      ActionCable = Class.new(RedisBase)

      STORAGES = (
        Gitlab::Redis::ALL_CLASSES.map do |redis_instance_class|
          instrumentation_class = Class.new(RedisBase)

          instrumentation_class.enable_redis_cluster_validation unless redis_instance_class == Gitlab::Redis::Queues

          const_set(redis_instance_class.store_name, instrumentation_class)
          instrumentation_class
        end << ActionCable
      ).freeze

      # Milliseconds represented in seconds (from 1 millisecond to 2 seconds).
      QUERY_TIME_BUCKETS = [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2].freeze

      class << self
        include ::Gitlab::Instrumentation::RedisPayload

        def storage_key
          nil
        end

        def payload
          super.merge(*STORAGES.flat_map(&:payload))
        end

        def detail_store
          STORAGES.flat_map do |storage|
            storage.detail_store.map { |details| details.merge(storage: storage.name.demodulize) }
          end
        end

        %i[get_request_count query_time read_bytes write_bytes].each do |method|
          define_method method do
            STORAGES.sum(&method)
          end
        end
      end
    end
  end
end
