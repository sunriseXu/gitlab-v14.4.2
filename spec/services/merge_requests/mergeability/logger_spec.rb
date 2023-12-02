# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::Logger, :request_store do
  let_it_be(:merge_request) { create(:merge_request) }

  subject(:logger) { described_class.new(merge_request: merge_request) }

  let(:caller_id) { 'a' }

  before do
    allow(Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return(caller_id)
  end

  def loggable_data(**extras)
    {
      'mergeability.expensive_operation.duration_s.values' => a_kind_of(Array),
      "mergeability_merge_request_id" => merge_request.id,
      "correlation_id" => a_kind_of(String),
      "mergeability_project_id" => merge_request.project.id
    }.merge(extras)
  end

  describe '#instrument' do
    let(:operation_count) { 1 }

    context 'when enabled' do
      it "returns the block's value" do
        expect(logger.instrument(mergeability_name: :expensive_operation) { 123 }).to eq(123)
      end

      it 'records durations of instrumented operations' do
        expect_next_instance_of(Gitlab::AppJsonLogger) do |app_logger|
          expect(app_logger).to receive(:info).with(match(a_hash_including(loggable_data)))
        end

        expect(logger.instrument(mergeability_name: :expensive_operation) { 123 }).to eq(123)

        logger.commit
      end

      context 'with multiple observations' do
        let(:operation_count) { 2 }

        it 'records durations of instrumented operations' do
          expect_next_instance_of(Gitlab::AppJsonLogger) do |app_logger|
            expect(app_logger).to receive(:info).with(match(a_hash_including(loggable_data)))
          end

          2.times do
            expect(logger.instrument(mergeability_name: :expensive_operation) { 123 }).to eq(123)
          end

          logger.commit
        end
      end

      context 'when its a query' do
        let(:extra_data) do
          {
            'mergeability.expensive_operation.db_count.values' => a_kind_of(Array),
            'mergeability.expensive_operation.db_main_count.values' => a_kind_of(Array),
            'mergeability.expensive_operation.db_main_duration_s.values' => a_kind_of(Array),
            'mergeability.expensive_operation.db_primary_count.values' => a_kind_of(Array),
            'mergeability.expensive_operation.db_primary_duration_s.values' => a_kind_of(Array)
          }
        end

        context 'with a single query' do
          it 'includes SQL metrics' do
            expect_next_instance_of(Gitlab::AppJsonLogger) do |app_logger|
              expect(app_logger).to receive(:info).with(match(a_hash_including(loggable_data(**extra_data))))
            end

            expect(logger.instrument(mergeability_name: :expensive_operation) { MergeRequest.count }).to eq(1)

            logger.commit
          end
        end

        context 'with multiple queries' do
          it 'includes SQL metrics' do
            expect_next_instance_of(Gitlab::AppJsonLogger) do |app_logger|
              expect(app_logger).to receive(:info).with(match(a_hash_including(loggable_data(**extra_data))))
            end

            expect(logger.instrument(mergeability_name: :expensive_operation) { Project.count + MergeRequest.count })
              .to eq(2)

            logger.commit
          end
        end
      end
    end

    context 'when disabled' do
      before do
        stub_feature_flags(mergeability_checks_logger: false)
      end

      it "returns the block's value" do
        expect(logger.instrument(mergeability_name: :expensive_operation) { 123 }).to eq(123)
      end

      it 'does not call the logger' do
        expect(Gitlab::AppJsonLogger).not_to receive(:new)

        expect(logger.instrument(mergeability_name: :expensive_operation) { Project.count + MergeRequest.count })
          .to eq(2)

        logger.commit
      end
    end

    it 'raises an error when block is not provided' do
      expect { logger.instrument(mergeability_name: :expensive_operation) }
        .to raise_error(ArgumentError, 'block not given')
    end
  end
end
