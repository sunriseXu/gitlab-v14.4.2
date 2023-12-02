# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container-Scanning.gitlab-ci.yml' do
  subject(:template) do
    <<~YAML
      include:
        - template: 'Security/Container-Scanning.latest.gitlab-ci.yml'
    YAML
  end

  describe 'the created pipeline' do
    let_it_be_with_refind(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { 'master' }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      context 'when branch pipeline' do
        it 'includes job' do
          expect(build_names).to match_array(%w[container_scanning])
        end
      end

      context 'when MR pipeline' do
        let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
        let(:feature_branch) { 'feature' }
        let(:pipeline) { service.execute(merge_request).payload }

        let(:merge_request) do
          create(:merge_request,
            source_project: project,
            source_branch: feature_branch,
            target_project: project,
            target_branch: default_branch)
        end

        before do
          project.repository.create_file(
            project.creator,
            'CHANGELOG.md',
            'contents',
            message: "Add CHANGELOG.md",
            branch_name: feature_branch)
        end

        it 'creates a pipeline with the expected jobs' do
          expect(pipeline).to be_merge_request_event
          expect(pipeline.errors.full_messages).to be_empty
          expect(build_names).to match_array(%w[container_scanning])
        end
      end

      context 'with CS_MAJOR_VERSION greater than 3' do
        before do
          create(:ci_variable, project: project, key: 'CS_MAJOR_VERSION', value: '4')
        end

        it 'includes job' do
          expect(build_names).to match_array(%w[container_scanning])
        end
      end

      context 'when CONTAINER_SCANNING_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'CONTAINER_SCANNING_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end
    end
  end
end
