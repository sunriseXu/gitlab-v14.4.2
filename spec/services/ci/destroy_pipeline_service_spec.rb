# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroyPipelineService do
  let_it_be(:project) { create(:project, :repository) }

  let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.id) }

  subject { described_class.new(project, user).execute(pipeline) }

  context 'user is owner' do
    let(:user) { project.first_owner }

    it 'destroys the pipeline' do
      subject

      expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'clears the cache', :use_clean_rails_redis_caching do
      create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)

      expect(project.pipeline_status.has_status?).to be_truthy

      subject

      # We need to reset lazy_latest_pipeline cache to simulate a new request
      BatchLoader::Executor.clear_current

      # Need to use find to avoid memoization
      expect(Project.find(project.id).pipeline_status.has_status?).to be_falsey
    end

    it 'does not log an audit event' do
      expect { subject }.not_to change { AuditEvent.count }
    end

    context 'when the pipeline has jobs' do
      let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'destroys associated jobs' do
        subject

        expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated stages' do
        stages = pipeline.stages

        subject

        expect(stages).to all(raise_error(ActiveRecord::RecordNotFound))
      end

      context 'when job has artifacts' do
        let!(:artifact) { create(:ci_job_artifact, :archive, job: build) }

        it 'destroys associated artifacts' do
          subject

          expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'inserts deleted objects for object storage files' do
          expect { subject }.to change { Ci::DeletedObject.count }
        end
      end

      context 'when job has trace chunks' do
        let(:connection_params) { Gitlab.config.artifacts.object_store.connection.symbolize_keys }
        let(:connection) { ::Fog::Storage.new(connection_params) }

        before do
          stub_object_storage(connection_params: connection_params, remote_directory: 'artifacts')
          stub_artifacts_object_storage
        end

        let!(:trace_chunk) { create(:ci_build_trace_chunk, :fog_with_data, build: build) }

        it 'destroys associated trace chunks' do
          subject

          expect { trace_chunk.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'removes data from object store' do
          expect { subject }.to change { Ci::BuildTraceChunks::Fog.new.data(trace_chunk) }
        end
      end
    end

    context 'when pipeline is in cancelable state', :sidekiq_inline do
      let!(:build) { create(:ci_build, :running, pipeline: pipeline) }
      let!(:child_pipeline) { create(:ci_pipeline, :running, child_of: pipeline) }
      let!(:child_build) { create(:ci_build, :running, pipeline: child_pipeline) }

      it 'cancels the pipelines sync' do
        # turn off deletion for all instances of pipeline to allow for testing cancellation
        allow(pipeline).to receive_message_chain(:reset, :destroy!)
        allow_next_found_instance_of(Ci::Pipeline) { |p| allow(p).to receive_message_chain(:reset, :destroy!) }

        # ensure cancellation happens sync so we accumulate minutes
        expect(::Ci::CancelPipelineWorker).not_to receive(:perform)

        subject

        expect(build.reload.status).to eq('canceled')
        expect(child_build.reload.status).to eq('canceled')
      end
    end
  end

  context 'user is not owner' do
    let(:user) { create(:user) }

    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
