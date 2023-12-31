# frozen_string_literal: true

# Add capabilities to increment a numeric model attribute efficiently by
# using Redis and flushing the increments asynchronously to the database
# after a period of time (10 minutes).
# When an attribute is incremented by a value, the increment is added
# to a Redis key. Then, FlushCounterIncrementsWorker will execute
# `flush_increments_to_database!` which removes increments from Redis for a
# given model attribute and updates the values in the database.
#
# @example:
#
#   class ProjectStatistics
#     include CounterAttribute
#
#     counter_attribute :commit_count
#     counter_attribute :storage_size
#   end
#
# To increment the counter we can use the method:
#   delayed_increment_counter(:commit_count, 3)
#
# It is possible to register callbacks to be executed after increments have
# been flushed to the database. Callbacks are not executed if there are no increments
# to flush.
#
#  counter_attribute_after_flush do |statistic|
#    Namespaces::ScheduleAggregationWorker.perform_async(statistic.namespace_id)
#  end
#
module CounterAttribute
  extend ActiveSupport::Concern
  extend AfterCommitQueue
  include Gitlab::ExclusiveLeaseHelpers

  LUA_STEAL_INCREMENT_SCRIPT = <<~EOS
    local increment_key, flushed_key = KEYS[1], KEYS[2]
    local increment_value = redis.call("get", increment_key) or 0
    local flushed_value = redis.call("incrby", flushed_key, increment_value)
    if flushed_value == 0 then
      redis.call("del", increment_key, flushed_key)
    else
      redis.call("del", increment_key)
    end
    return flushed_value
  EOS

  WORKER_DELAY = 10.minutes
  WORKER_LOCK_TTL = 10.minutes

  class_methods do
    def counter_attribute(attribute)
      counter_attributes << attribute
    end

    def counter_attributes
      @counter_attributes ||= Set.new
    end

    def after_flush_callbacks
      @after_flush_callbacks ||= []
    end

    # perform registered callbacks after increments have been flushed to the database
    def counter_attribute_after_flush(&callback)
      after_flush_callbacks << callback
    end

    def counter_attribute_enabled?(attribute)
      counter_attributes.include?(attribute)
    end
  end

  # This method must only be called by FlushCounterIncrementsWorker
  # because it should run asynchronously and with exclusive lease.
  # This will
  #  1. temporarily move the pending increment for a given attribute
  #     to a relative "flushed" Redis key, delete the increment key and return
  #     the value. If new increments are performed at this point, the increment
  #     key is recreated as part of `delayed_increment_counter`.
  #     The "flushed" key is used to ensure that we can keep incrementing
  #     counters in Redis while flushing existing values.
  #  2. then the value is used to update the counter in the database.
  #  3. finally the "flushed" key is deleted.
  def flush_increments_to_database!(attribute)
    lock_key = counter_lock_key(attribute)

    with_exclusive_lease(lock_key) do
      previous_db_value = read_attribute(attribute)
      increment_key = counter_key(attribute)
      flushed_key = counter_flushed_key(attribute)
      increment_value = steal_increments(increment_key, flushed_key)
      new_db_value = nil

      next if increment_value == 0

      transaction do
        unsafe_update_counters(id, attribute => increment_value)
        redis_state { |redis| redis.del(flushed_key) }
        new_db_value = reset.read_attribute(attribute)
      end

      execute_after_flush_callbacks

      log_flush_counter(attribute, increment_value, previous_db_value, new_db_value)
    end
  end

  def delayed_increment_counter(attribute, increment)
    raise ArgumentError, "#{attribute} is not a counter attribute" unless counter_attribute_enabled?(attribute)

    return if increment == 0

    run_after_commit_or_now do
      increment_counter(attribute, increment)

      FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, self.class.name, self.id, attribute)
    end

    true
  end

  def increment_counter(attribute, increment)
    if counter_attribute_enabled?(attribute)
      new_value = redis_state do |redis|
        redis.incrby(counter_key(attribute), increment)
      end

      log_increment_counter(attribute, increment, new_value)
    end
  end

  def clear_counter!(attribute)
    if counter_attribute_enabled?(attribute)
      redis_state { |redis| redis.del(counter_key(attribute)) }

      log_clear_counter(attribute)
    end
  end

  def get_counter_value(attribute)
    if counter_attribute_enabled?(attribute)
      redis_state do |redis|
        redis.get(counter_key(attribute)).to_i
      end
    end
  end

  def counter_key(attribute)
    "project:{#{project_id}}:counters:#{self.class}:#{id}:#{attribute}"
  end

  def counter_flushed_key(attribute)
    counter_key(attribute) + ':flushed'
  end

  def counter_lock_key(attribute)
    counter_key(attribute) + ':lock'
  end

  def counter_attribute_enabled?(attribute)
    self.class.counter_attribute_enabled?(attribute)
  end

  private

  def steal_increments(increment_key, flushed_key)
    redis_state do |redis|
      redis.eval(LUA_STEAL_INCREMENT_SCRIPT, keys: [increment_key, flushed_key])
    end
  end

  def unsafe_update_counters(id, increments)
    self.class.update_counters(id, increments)
  end

  def execute_after_flush_callbacks
    self.class.after_flush_callbacks.each do |callback|
      callback.call(self)
    end
  end

  def redis_state(&block)
    Gitlab::Redis::SharedState.with(&block)
  end

  def with_exclusive_lease(lock_key)
    in_lock(lock_key, ttl: WORKER_LOCK_TTL) do
      yield
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
    # a worker is already updating the counters
  end

  def log_increment_counter(attribute, increment, new_value)
    payload = Gitlab::ApplicationContext.current.merge(
      message: 'Increment counter attribute',
      attribute: attribute,
      project_id: project_id,
      increment: increment,
      new_counter_value: new_value,
      current_db_value: read_attribute(attribute)
    )

    Gitlab::AppLogger.info(payload)
  end

  def log_flush_counter(attribute, increment, previous_db_value, new_db_value)
    payload = Gitlab::ApplicationContext.current.merge(
      message: 'Flush counter attribute to database',
      attribute: attribute,
      project_id: project_id,
      increment: increment,
      previous_db_value: previous_db_value,
      new_db_value: new_db_value
    )

    Gitlab::AppLogger.info(payload)
  end

  def log_clear_counter(attribute)
    payload = Gitlab::ApplicationContext.current.merge(
      message: 'Clear counter attribute',
      attribute: attribute,
      project_id: project_id
    )

    Gitlab::AppLogger.info(payload)
  end
end
