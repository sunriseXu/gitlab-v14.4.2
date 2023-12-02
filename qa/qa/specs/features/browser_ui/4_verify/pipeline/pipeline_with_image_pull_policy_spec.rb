# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pipeline with image:pull_policy' do
      let(:runner_name) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:job_name) { "test-job-#{pull_policies.join('-')}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipeline-with-image-pull-policy'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = runner_name
          runner.tags = [runner_name]
          runner.executor = :docker
        end
      end

      before do
        update_runner_policy(allowed_policies)
        add_ci_file
        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      context(
        'when policy is allowed',
        quarantine: { type: :flaky, issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/369397' }
      ) do
        let(:allowed_policies) { %w[if-not-present always never] }

        where do
          {
            'with [always] policy' => {
              pull_policies: %w[always],
              pull_image: true,
              message: 'Pulling docker image ruby:2.6',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367154'
            },
            'with [always if-not-present] policies' => {
              pull_policies: %w[always if-not-present],
              pull_image: true,
              message: 'Pulling docker image ruby:2.6',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368857'
            },
            'with [if-not-present] policy' => {
              pull_policies: %w[if-not-present],
              pull_image: true,
              message: 'Using locally found image version due to "if-not-present" pull policy',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368858'
            },
            'with [never] policy' => {
              pull_policies: %w[never],
              pull_image: false,
              message: 'Pulling docker image',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368859'
            }
          }
        end

        with_them do
          it 'applies pull policy in job correctly', testcase: params[:testcase] do
            visit_job

            if pull_image
              expect(job_log).to have_content(message),
                                 "Expected to find #{message} in #{job_log}, but didn't."
            else
              expect(job_log).not_to have_content(message),
                                 "Found #{message} in #{job_log}, but didn't expect to."
            end
          end
        end
      end

      context 'when policy is not allowed' do
        let(:allowed_policies) { %w[never] }
        let(:pull_policies) { %w[always] }

        let(:message) do
          'ERROR: Preparation failed: the configured PullPolicies ([always])'\
            ' are not allowed by AllowedPullPolicies ([never])'
        end

        it(
          'fails job with policy not allowed message',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368853',
          quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/371420', type: :stale }
        ) do
          visit_job

          expect(job_log).to have_content(message),
                             "Expected to find #{message} in #{job_log}, but didn't."
        end
      end

      private

      def update_runner_policy(allowed_policies)
        Runtime::Logger.info('Updating runner config to allow pull policies...')

        # Copy config.toml file from docker to local
        # Update local file with allowed_pull_policies config
        # Copy file with new content back to docker
        tempdir = Tempfile.new('config.toml')
        QA::Service::Shellout.shell("docker cp #{runner_name}:/etc/gitlab-runner/config.toml #{tempdir.path}")

        File.open(tempdir.path, 'a') do |f|
          f << %Q[    allowed_pull_policies = #{allowed_policies}\n]
        end

        QA::Service::Shellout.shell("docker cp #{tempdir.path} #{runner_name}:/etc/gitlab-runner/config.toml")

        tempdir.close!

        # Give runner some time to pick up new configuration
        sleep(30)
      end

      def add_ci_file
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  default:
                    image: ruby:2.6
                    tags: [#{runner_name}]

                  #{job_name}:
                    script: echo "Using pull policies #{pull_policies}"
                    image:
                      name: ruby:2.6
                      pull_policy: #{pull_policies}
                YAML
              }
            ]
          )
        end
      end

      def visit_job
        Page::Project::Pipeline::Show.perform do |show|
          Support::Waiter.wait_until { show.completed? }

          show.click_job(job_name)
        end
      end

      def job_log
        Page::Project::Job::Show.perform(&:output)
      end
    end
  end
end
