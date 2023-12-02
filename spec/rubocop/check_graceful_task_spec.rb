# frozen_string_literal: true

require 'fast_spec_helper'
require 'stringio'

require_relative '../support/helpers/next_instance_of'
require_relative '../../rubocop/check_graceful_task'

RSpec.describe RuboCop::CheckGracefulTask do
  include NextInstanceOf

  let(:output) { StringIO.new }

  subject(:task) { described_class.new(output) }

  describe '#run' do
    let(:status_success) { RuboCop::CLI::STATUS_SUCCESS }
    let(:status_offenses) { RuboCop::CLI::STATUS_OFFENSES }
    let(:rubocop_status) { status_success }
    let(:adjusted_rubocop_status) { rubocop_status }

    subject { task.run(args) }

    before do
      # Don't notify Slack accidentally.
      allow(Gitlab::Popen).to receive(:popen).and_raise('Notifications forbidden.')
      stub_const('ENV', ENV.to_hash.delete_if { |key, _| key.start_with?('CI_') })

      allow_next_instance_of(RuboCop::CLI) do |cli|
        allow(cli).to receive(:run).and_return(rubocop_status)
      end

      allow(RuboCop::Formatter::GracefulFormatter)
        .to receive(:adjusted_exit_status).and_return(adjusted_rubocop_status)
    end

    shared_examples 'rubocop scan' do |rubocop_args:|
      it 'invokes a RuboCop scan' do
        rubocop_options = %w[--parallel --format RuboCop::Formatter::GracefulFormatter]
        rubocop_options.concat(rubocop_args)

        expect_next_instance_of(RuboCop::CLI) do |cli|
          expect(cli).to receive(:run).with(rubocop_options).and_return(rubocop_status)
        end

        subject

        expect(output.string)
          .to include('Running RuboCop in graceful mode:')
          .and include("rubocop #{rubocop_options.join(' ')}")
          .and include('This might take a while...')
      end
    end

    context 'without args' do
      let(:args) { [] }

      it_behaves_like 'rubocop scan', rubocop_args: []

      context 'with adjusted rubocop status' do
        let(:rubocop_status) { status_offenses }
        let(:adjusted_rubocop_status) { status_success }

        context 'with sufficient environment variables' do
          let(:channel) { 'f_rubocop' }

          before do
            env = {
              'CI_SLACK_WEBHOOK_URL' => 'webhook_url',
              'CI_JOB_NAME' => 'job_name',
              'CI_JOB_URL' => 'job_url'
            }

            stub_const('ENV', ENV.to_hash.update(env))
          end

          it 'notifies slack' do
            popen_args = ['scripts/slack', channel, kind_of(String), 'rubocop', kind_of(String)]
            popen_result = ['', 0]
            expect(Gitlab::Popen).to receive(:popen).with(popen_args).and_return(popen_result)

            subject

            expect(output.string).to include("Notifying Slack ##{channel}.")
          end

          context 'with when notification fails' do
            it 'prints that notification failed' do
              popen_result = ['', 1]
              expect(Gitlab::Popen).to receive(:popen).and_return(popen_result)

              subject

              expect(output.string).to include("Failed to notify Slack channel ##{channel}.")
            end
          end
        end

        context 'with missing environment variables' do
          it 'skips slack notification' do
            expect(Gitlab::Popen).not_to receive(:popen)

            subject

            expect(output.string).to include('Skipping Slack notification.')
          end
        end
      end
    end

    context 'with args' do
      let(:args) { %w[a.rb Lint/EmptyFile b.rb Lint/Syntax] }

      it_behaves_like 'rubocop scan', rubocop_args: %w[--only Lint/EmptyFile,Lint/Syntax a.rb b.rb]

      it 'does not notify slack' do
        expect(Gitlab::Popen).not_to receive(:popen)

        subject

        expect(output.string).not_to include('Skipping Slack notification.')
      end
    end
  end
end
