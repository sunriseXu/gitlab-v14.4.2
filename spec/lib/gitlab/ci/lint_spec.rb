# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Lint do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:lint) { described_class.new(project: project, current_user: user) }
  let(:ref) { project.default_branch }

  describe '#validate' do
    subject { lint.validate(content, dry_run: dry_run, ref: ref) }

    shared_examples 'content is valid' do
      let(:content) do
        <<~YAML
        build:
          stage: build
          before_script:
            - before_build
          script: echo
          environment: staging
          when: manual
        rspec:
          stage: test
          script: rspec
          after_script:
            - after_rspec
          tags: [docker]
        YAML
      end

      it 'returns a valid result', :aggregate_failures do
        expect(subject).to be_valid

        expect(subject.errors).to be_empty
        expect(subject.warnings).to be_empty
        expect(subject.jobs).to be_present

        build_job = subject.jobs.first
        expect(build_job[:name]).to eq('build')
        expect(build_job[:stage]).to eq('build')
        expect(build_job[:before_script]).to eq(['before_build'])
        expect(build_job[:script]).to eq(['echo'])
        expect(build_job.fetch(:after_script)).to eq([])
        expect(build_job[:tag_list]).to eq([])
        expect(build_job[:environment]).to eq('staging')
        expect(build_job[:when]).to eq('manual')
        expect(build_job[:allow_failure]).to eq(true)

        rspec_job = subject.jobs.last
        expect(rspec_job[:name]).to eq('rspec')
        expect(rspec_job[:stage]).to eq('test')
        expect(rspec_job.fetch(:before_script)).to eq([])
        expect(rspec_job[:script]).to eq(['rspec'])
        expect(rspec_job[:after_script]).to eq(['after_rspec'])
        expect(rspec_job[:tag_list]).to eq(['docker'])
        expect(rspec_job.fetch(:environment)).to be_nil
        expect(rspec_job[:when]).to eq('on_success')
        expect(rspec_job[:allow_failure]).to eq(false)
      end
    end

    shared_examples 'sets config metadata' do
      let(:content) do
        <<~YAML
        :include:
          :local: another-gitlab-ci.yml
        :test_job:
          :stage: test
          :script: echo
        YAML
      end

      let(:included_content) do
        <<~YAML
        :another_job:
          :script: echo
        YAML
      end

      before do
        project.repository.create_file(
          project.creator,
          'another-gitlab-ci.yml',
          included_content,
          message: 'Automatically created another-gitlab-ci.yml',
          branch_name: 'master'
        )
      end

      after do
        project.repository.delete_file(
          project.creator,
          'another-gitlab-ci.yml',
          message: 'Remove another-gitlab-ci.yml',
          branch_name: 'master'
        )
      end

      it 'sets merged_config' do
        root_config = YAML.safe_load(content, [Symbol])
        included_config = YAML.safe_load(included_content, [Symbol])
        expected_config = included_config.merge(root_config).except(:include).deep_stringify_keys

        expect(subject.merged_yaml).to eq(expected_config.to_yaml)
      end

      it 'sets includes' do
        expect(subject.includes).to contain_exactly(
          {
            type: :local,
            location: 'another-gitlab-ci.yml',
            blob: "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/another-gitlab-ci.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/another-gitlab-ci.yml",
            extra: {},
            context_project: project.full_path,
            context_sha: project.commit.sha
          }
        )
      end
    end

    shared_examples 'content with errors and warnings' do
      context 'when content has errors' do
        let(:content) do
          <<~YAML
          build:
            invalid: syntax
          YAML
        end

        it 'returns a result with errors' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include(/jobs build config should implement a script: or a trigger: keyword/)
        end
      end

      context 'when content has warnings' do
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          YAML
        end

        it 'returns a result with warnings' do
          expect(subject).to be_valid
          expect(subject.warnings).to include(/rspec may allow multiple pipelines to run/)
        end
      end

      context 'when content has more warnings than max limit' do
        # content will result in 2 warnings
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          rspec2:
            script: rspec
            rules:
              - when: always
          YAML
        end

        before do
          stub_const('Gitlab::Ci::Warnings::MAX_LIMIT', 1)
        end

        it 'returns a result with warnings' do
          expect(subject).to be_valid
          expect(subject.warnings.size).to eq(1)
        end
      end

      context 'when content has errors and warnings' do
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          karma:
            script: karma
            unknown: key
          YAML
        end

        it 'returns a result with errors and warnings' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include(/karma config contains unknown keys/)
          expect(subject.warnings).to include(/rspec may allow multiple pipelines to run/)
        end
      end
    end

    shared_context 'advanced validations' do
      let(:content) do
        <<~YAML
        build:
          stage: build
          script: echo
          rules:
            - if: '$CI_MERGE_REQUEST_ID'
        test:
          stage: test
          script: echo
          needs: [build]
        YAML
      end
    end

    context 'when user has permissions to write the ref' do
      before do
        project.add_developer(user)
      end

      context 'when using default static mode' do
        let(:dry_run) { false }

        it_behaves_like 'content with errors and warnings'

        it_behaves_like 'content is valid' do
          it 'includes extra attributes' do
            subject.jobs.each do |job|
              expect(job[:only]).to eq(refs: %w[branches tags])
              expect(job.fetch(:except)).to be_nil
            end
          end
        end

        it_behaves_like 'sets config metadata'

        include_context 'advanced validations' do
          it 'does not catch advanced logical errors' do
            expect(subject).to be_valid
            expect(subject.errors).to be_empty
          end
        end

        it 'uses YamlProcessor' do
          expect(Gitlab::Ci::YamlProcessor)
            .to receive(:new)
            .and_call_original

          subject
        end
      end

      context 'when using dry run mode' do
        let(:dry_run) { true }

        it_behaves_like 'content with errors and warnings'

        it_behaves_like 'content is valid' do
          it 'does not include extra attributes' do
            subject.jobs.each do |job|
              expect(job.key?(:only)).to be_falsey
              expect(job.key?(:except)).to be_falsey
            end
          end
        end

        context 'when using a ref other than the default branch' do
          let(:ref) { 'feature' }
          let(:content) do
            <<~YAML
            build:
              stage: build
              script: echo 1
              rules:
                - if: "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"
            test:
              stage: test
              script: echo 2
              rules:
                - if: "$CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH"
            YAML
          end

          it 'includes only jobs that are excluded on the default branch' do
            expect(subject.jobs.size).to eq(1)
            expect(subject.jobs[0][:name]).to eq('test')
          end
        end

        it_behaves_like 'sets config metadata'

        include_context 'advanced validations' do
          it 'runs advanced logical validations' do
            expect(subject).not_to be_valid
            expect(subject.errors).to eq(["'test' job needs 'build' job, but 'build' is not in any previous stage"])
          end
        end

        it 'uses Ci::CreatePipelineService' do
          expect(::Ci::CreatePipelineService)
            .to receive(:new)
            .and_call_original

          subject
        end
      end
    end

    context 'when user does not have permissions to write the ref' do
      before do
        project.add_reporter(user)
      end

      context 'when using default static mode' do
        let(:dry_run) { false }

        it_behaves_like 'content is valid'
      end

      context 'when using dry run mode' do
        let(:dry_run) { true }

        let(:content) do
          <<~YAML
          job:
            script: echo
          YAML
        end

        it 'does not allow validation' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include('Insufficient permissions to create a new pipeline')
        end
      end
    end
  end

  context 'pipeline logger' do
    let(:counters) do
      {
        'count' => a_kind_of(Numeric),
        'avg' => a_kind_of(Numeric),
        'max' => a_kind_of(Numeric),
        'min' => a_kind_of(Numeric)
      }
    end

    let(:loggable_data) do
      {
        'class' => 'Gitlab::Ci::Pipeline::Logger',
        'config_build_context_duration_s' => counters,
        'config_build_variables_duration_s' => counters,
        'config_compose_duration_s' => counters,
        'config_expand_duration_s' => counters,
        'config_external_process_duration_s' => counters,
        'config_stages_inject_duration_s' => counters,
        'config_tags_resolve_duration_s' => counters,
        'config_yaml_extend_duration_s' => counters,
        'config_yaml_load_duration_s' => counters,
        'pipeline_creation_caller' => 'Gitlab::Ci::Lint',
        'pipeline_creation_service_duration_s' => a_kind_of(Numeric),
        'pipeline_persisted' => false,
        'pipeline_source' => 'unknown',
        'project_id' => project&.id,
        'yaml_process_duration_s' => counters
      }
    end

    let(:content) do
      <<~YAML
      build:
        script: echo
      YAML
    end

    subject(:validate) { lint.validate(content, dry_run: false) }

    before do
      project&.add_developer(user)
    end

    context 'when the duration is under the threshold' do
      it 'does not create a log entry' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        validate
      end
    end

    context 'when the durations exceeds the threshold' do
      let(:timer) do
        proc do
          @timer = @timer.to_i + 30
        end
      end

      before do
        allow(Gitlab::Ci::Pipeline::Logger)
          .to receive(:current_monotonic_time) { timer.call }
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(loggable_data)

        validate
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(ci_pipeline_creation_logger: false)
        end

        it 'does not create a log entry' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          validate
        end
      end

      context 'when project is not provided' do
        let(:project) { nil }

        let(:project_nil_loggable_data) do
          loggable_data.except('project_id')
        end

        it 'creates a log entry without project_id' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(project_nil_loggable_data)

          validate
        end
      end
    end
  end
end
