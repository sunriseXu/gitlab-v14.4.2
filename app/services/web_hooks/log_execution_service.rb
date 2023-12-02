# frozen_string_literal: true

module WebHooks
  class LogExecutionService
    include ::Gitlab::ExclusiveLeaseHelpers

    LOCK_TTL = 15.seconds.freeze
    LOCK_SLEEP = 0.25.seconds.freeze
    LOCK_RETRY = 65

    attr_reader :hook, :log_data, :response_category

    def initialize(hook:, log_data:, response_category:)
      @hook = hook
      @log_data = log_data.transform_keys(&:to_sym)
      @response_category = response_category
    end

    def execute
      update_hook_failure_state
      log_execution
    end

    private

    def log_execution
      WebHookLog.create!(web_hook: hook, **log_data)
    end

    # Perform this operation within an `Gitlab::ExclusiveLease` lock to make it
    # safe to be called concurrently from different workers.
    def update_hook_failure_state
      in_lock(lock_name, ttl: LOCK_TTL, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRY) do |retried|
        hook.reset # Reload within the lock so properties are guaranteed to be current.

        case response_category
        when :ok
          hook.enable!
        when :error
          hook.backoff!
        when :failed
          hook.failed!
        end

        hook.update_last_failure
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      raise if raise_lock_error?
    end

    def lock_name
      "web_hooks:update_hook_failure_state:#{hook.id}"
    end

    # Allow an error to be raised after failing to obtain a lease only if the hook
    # is not already in the correct failure state.
    def raise_lock_error?
      hook.reset # Reload so properties are guaranteed to be current.

      hook.executable? != (response_category == :ok)
    end
  end
end
