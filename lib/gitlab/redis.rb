# frozen_string_literal: true

module Gitlab
  module Redis
    # List all Gitlab::Redis::Wrapper descendants that are backed by an actual
    # separate redis instance here.
    #
    # This will make sure the connection pool is initialized on application boot in
    # config/initializers/7_redis.rb, instrumented, and used in health- & readiness checks.
    ALL_CLASSES = [
      Gitlab::Redis::Cache,
      Gitlab::Redis::Queues,
      Gitlab::Redis::RateLimiting,
      Gitlab::Redis::Sessions,
      Gitlab::Redis::SharedState,
      Gitlab::Redis::TraceChunks
    ].freeze
  end
end
