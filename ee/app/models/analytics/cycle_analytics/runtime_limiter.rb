# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class RuntimeLimiter
      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      attr_reader :max_runtime, :start_time

      def initialize(max_runtime)
        @start_time = monotonic_time
        @max_runtime = max_runtime
      end

      def elapsed_time
        monotonic_time - start_time
      end

      def over_time?
        elapsed_time >= max_runtime
      end
    end
  end
end
