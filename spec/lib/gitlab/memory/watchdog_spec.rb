# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures, :prometheus do
  context 'watchdog' do
    let(:logger) { instance_double(::Logger) }
    let(:handler) { instance_double(described_class::NullHandler) }

    let(:heap_frag_limit_gauge) { instance_double(::Prometheus::Client::Gauge) }
    let(:violations_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }

    let(:sleep_time) { 0.1 }
    let(:max_heap_fragmentation) { 0.2 }
    let(:max_mem_growth) { 2 }

    # Defaults that will not trigger any events.
    let(:fragmentation) { 0 }
    let(:worker_memory) { 0 }
    let(:primary_memory) { 0 }
    let(:max_strikes) { 0 }

    # Tests should set this to control the number of loop iterations in `call`.
    let(:watchdog_iterations) { 1 }

    subject(:watchdog) do
      described_class.new(handler: handler, logger: logger, sleep_time_seconds: sleep_time,
                          max_strikes: max_strikes, max_mem_growth: max_mem_growth,
                          max_heap_fragmentation: max_heap_fragmentation).tap do |instance|
        # We need to defuse `sleep` and stop the internal loop after N iterations.
        iterations = 0
        allow(instance).to receive(:sleep) do
          instance.stop if (iterations += 1) > watchdog_iterations
        end
      end
    end

    def stub_prometheus_metrics
      allow(Gitlab::Metrics).to receive(:gauge)
        .with(:gitlab_memwd_heap_frag_limit, anything)
        .and_return(heap_frag_limit_gauge)
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_memwd_violations_total, anything, anything)
        .and_return(violations_counter)
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_memwd_violations_handled_total, anything, anything)
        .and_return(violations_handled_counter)

      allow(heap_frag_limit_gauge).to receive(:set)
      allow(violations_counter).to receive(:increment)
      allow(violations_handled_counter).to receive(:increment)
    end

    before do
      stub_prometheus_metrics

      allow(handler).to receive(:call).and_return(true)

      allow(logger).to receive(:warn)
      allow(logger).to receive(:info)

      allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(fragmentation)
      allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).and_return({ uss: worker_memory })
      allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(
        pid: Gitlab::Cluster::PRIMARY_PID
      ).and_return({ uss: primary_memory })

      allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
    end

    context 'when created' do
      it 'sets the heap fragmentation limit gauge' do
        expect(heap_frag_limit_gauge).to receive(:set).with({}, max_heap_fragmentation)

        watchdog
      end

      context 'when no settings are set in the environment' do
        it 'initializes with defaults' do
          watchdog = described_class.new(handler: handler, logger: logger)

          expect(watchdog.max_heap_fragmentation).to eq(described_class::DEFAULT_MAX_HEAP_FRAG)
          expect(watchdog.max_mem_growth).to eq(described_class::DEFAULT_MAX_MEM_GROWTH)
          expect(watchdog.max_strikes).to eq(described_class::DEFAULT_MAX_STRIKES)
          expect(watchdog.sleep_time_seconds).to eq(described_class::DEFAULT_SLEEP_TIME_SECONDS)
        end
      end

      context 'when settings are passed through the environment' do
        before do
          stub_env('GITLAB_MEMWD_MAX_HEAP_FRAG', 1)
          stub_env('GITLAB_MEMWD_MAX_STRIKES', 2)
          stub_env('GITLAB_MEMWD_SLEEP_TIME_SEC', 3)
          stub_env('GITLAB_MEMWD_MAX_MEM_GROWTH', 4)
        end

        it 'initializes with these settings' do
          watchdog = described_class.new(handler: handler, logger: logger)

          expect(watchdog.max_heap_fragmentation).to eq(1)
          expect(watchdog.max_strikes).to eq(2)
          expect(watchdog.sleep_time_seconds).to eq(3)
          expect(watchdog.max_mem_growth).to eq(4)
        end
      end
    end

    shared_examples 'has strikes left' do |stat|
      context 'when process has not exceeded allowed number of strikes' do
        let(:watchdog_iterations) { max_strikes }

        it 'does not signal the handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end

        it 'does not log any events' do
          expect(logger).not_to receive(:warn)

          watchdog.call
        end

        it 'increments the violations counter' do
          expect(violations_counter).to receive(:increment).with(reason: stat).exactly(watchdog_iterations)

          watchdog.call
        end

        it 'does not increment violations handled counter' do
          expect(violations_handled_counter).not_to receive(:increment)

          watchdog.call
        end
      end
    end

    shared_examples 'no strikes left' do |stat|
      it 'signals the handler and resets strike counter' do
        expect(handler).to receive(:call).and_return(true)

        watchdog.call

        expect(watchdog.strikes(stat.to_sym)).to eq(0)
      end

      it 'increments both the violations and violations handled counters' do
        expect(violations_counter).to receive(:increment).with(reason: stat).exactly(watchdog_iterations)
        expect(violations_handled_counter).to receive(:increment).with(reason: stat)

        watchdog.call
      end

      context 'when enforce_memory_watchdog ops toggle is off' do
        before do
          stub_feature_flags(enforce_memory_watchdog: false)
        end

        it 'always uses the NullHandler' do
          expect(handler).not_to receive(:call)
          expect(described_class::NullHandler.instance).to receive(:call).and_return(true)

          watchdog.call
        end
      end

      context 'when handler result is true' do
        it 'considers the event handled and stops itself' do
          expect(handler).to receive(:call).once.and_return(true)
          expect(logger).to receive(:info).with(hash_including(message: 'stopped'))

          watchdog.call
        end
      end

      context 'when handler result is false' do
        let(:max_strikes) { 0 } # to make sure the handler fires each iteration
        let(:watchdog_iterations) { 3 }

        it 'keeps running' do
          expect(violations_counter).to receive(:increment).exactly(watchdog_iterations)
          expect(violations_handled_counter).to receive(:increment).exactly(watchdog_iterations)
          # Return true the third time to terminate the daemon.
          expect(handler).to receive(:call).and_return(false, false, true)

          watchdog.call
        end
      end
    end

    context 'when monitoring memory growth' do
      let(:primary_memory) { 2048 }

      context 'when process does not exceed threshold' do
        let(:worker_memory) { max_mem_growth * primary_memory - 1 }

        it 'does not signal the handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end

      context 'when process exceeds threshold permanently' do
        let(:worker_memory) { max_mem_growth * primary_memory + 1 }
        let(:max_strikes) { 3 }

        it_behaves_like 'has strikes left', 'mem_growth'

        context 'when process exceeds the allowed number of strikes' do
          let(:watchdog_iterations) { max_strikes + 1 }

          it_behaves_like 'no strikes left', 'mem_growth'

          it 'only reads reference memory once' do
            expect(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss)
              .with(pid: Gitlab::Cluster::PRIMARY_PID)
              .once

            watchdog.call
          end

          it 'logs the event' do
            expect(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(1024)
            expect(logger).to receive(:warn).with({
              message: 'memory limit exceeded',
              pid: Process.pid,
              worker_id: 'worker_1',
              memwd_handler_class: 'RSpec::Mocks::InstanceVerifyingDouble',
              memwd_sleep_time_s: sleep_time,
              memwd_max_uss_bytes: max_mem_growth * primary_memory,
              memwd_ref_uss_bytes: primary_memory,
              memwd_uss_bytes: worker_memory,
              memwd_rss_bytes: 1024,
              memwd_max_strikes: max_strikes,
              memwd_cur_strikes: max_strikes + 1
            })

            watchdog.call
          end
        end
      end

      context 'when process exceeds threshold temporarily' do
        let(:worker_memory) { max_mem_growth * primary_memory }
        let(:max_strikes) { 1 }
        let(:watchdog_iterations) { 4 }

        before do
          allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).and_return(
            { uss: worker_memory - 0.1 },
            { uss: worker_memory + 0.2 },
            { uss: worker_memory - 0.1 },
            { uss: worker_memory + 0.1 }
          )
          allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(
            pid: Gitlab::Cluster::PRIMARY_PID
          ).and_return({ uss: primary_memory })
        end

        it 'does not signal the handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end
    end

    context 'when monitoring heap fragmentation' do
      context 'when process does not exceed threshold' do
        let(:fragmentation) { max_heap_fragmentation - 0.1 }

        it 'does not signal the handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end

      context 'when process exceeds threshold permanently' do
        let(:fragmentation) { max_heap_fragmentation + 0.1 }
        let(:max_strikes) { 3 }

        it_behaves_like 'has strikes left', 'heap_frag'

        context 'when process exceeds the allowed number of strikes' do
          let(:watchdog_iterations) { max_strikes + 1 }

          it_behaves_like 'no strikes left', 'heap_frag'

          it 'logs the event' do
            expect(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(1024)
            expect(logger).to receive(:warn).with({
              message: 'heap fragmentation limit exceeded',
              pid: Process.pid,
              worker_id: 'worker_1',
              memwd_handler_class: 'RSpec::Mocks::InstanceVerifyingDouble',
              memwd_sleep_time_s: sleep_time,
              memwd_max_heap_frag: max_heap_fragmentation,
              memwd_cur_heap_frag: fragmentation,
              memwd_max_strikes: max_strikes,
              memwd_cur_strikes: max_strikes + 1,
              memwd_rss_bytes: 1024
            })

            watchdog.call
          end
        end
      end

      context 'when process exceeds threshold temporarily' do
        let(:fragmentation) { max_heap_fragmentation }
        let(:max_strikes) { 1 }
        let(:watchdog_iterations) { 4 }

        before do
          allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(
            fragmentation - 0.1,
            fragmentation + 0.2,
            fragmentation - 0.1,
            fragmentation + 0.1
          )
        end

        it 'does not signal the handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end
    end

    context 'when both memory fragmentation and growth exceed thresholds' do
      let(:fragmentation) { max_heap_fragmentation + 0.1 }
      let(:primary_memory) { 2048 }
      let(:worker_memory) { max_mem_growth * primary_memory + 1 }
      let(:watchdog_iterations) { max_strikes + 1 }

      it 'only calls the handler once' do
        expect(handler).to receive(:call).once.and_return(true)

        watchdog.call
      end
    end

    context 'when gitlab_memory_watchdog ops toggle is off' do
      before do
        stub_feature_flags(gitlab_memory_watchdog: false)
      end

      it 'does not monitor heap fragmentation' do
        expect(Gitlab::Metrics::Memory).not_to receive(:gc_heap_fragmentation)

        watchdog.call
      end

      it 'does not monitor memory growth' do
        expect(Gitlab::Metrics::System).not_to receive(:memory_usage_uss_pss)

        watchdog.call
      end
    end
  end

  context 'handlers' do
    context 'NullHandler' do
      subject(:handler) { described_class::NullHandler.instance }

      describe '#call' do
        it 'does nothing' do
          expect(handler.call).to be(false)
        end
      end
    end

    context 'TermProcessHandler' do
      subject(:handler) { described_class::TermProcessHandler.new(42) }

      describe '#call' do
        it 'sends SIGTERM to the current process' do
          expect(Process).to receive(:kill).with(:TERM, 42)

          expect(handler.call).to be(true)
        end
      end
    end

    context 'PumaHandler' do
      # rubocop: disable RSpec/VerifiedDoubles
      # In tests, the Puma constant is not loaded so we cannot make this an instance_double.
      let(:puma_worker_handle_class) { double('Puma::Cluster::WorkerHandle') }
      let(:puma_worker_handle) { double('worker') }
      # rubocop: enable RSpec/VerifiedDoubles

      subject(:handler) { described_class::PumaHandler.new({}) }

      before do
        stub_const('::Puma::Cluster::WorkerHandle', puma_worker_handle_class)
      end

      describe '#call' do
        it 'invokes orderly termination via Puma API' do
          expect(puma_worker_handle_class).to receive(:new).and_return(puma_worker_handle)
          expect(puma_worker_handle).to receive(:term)

          expect(handler.call).to be(true)
        end
      end
    end
  end
end
