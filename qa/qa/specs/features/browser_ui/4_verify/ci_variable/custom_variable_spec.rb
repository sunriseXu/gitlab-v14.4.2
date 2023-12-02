# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pipeline with customizable variable' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:pipeline_job_name) { 'customizable-variable' }
      let(:variable_custom_value) { 'Custom Foo' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-customizable-variable-pipeline'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  variables:
                    FOO:
                      value: "Default Foo"
                      description: "This is a description for the foo variable"
                  #{pipeline_job_name}:
                    tags:
                      - #{executor}
                    script: echo "$FOO"
                YAML
              }
            ]
          )
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform do |index|
          index.click_run_pipeline_button
        end
      end

      after do
        [runner, project].each(&:remove_via_api!)
      end

      it(
        'manually creates a pipeline and uses the defined custom variable value',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/361814'
      ) do
        Page::Project::Pipeline::New.perform do |new|
          new.configure_variable(value: variable_custom_value)
          new.click_run_pipeline_button
        end

        Page::Project::Pipeline::Show.perform do |show|
          Support::Waiter.wait_until { show.passed? }
        end

        job = Resource::Job.fabricate_via_api! do |job|
          job.id = project.job_by_name(pipeline_job_name)[:id]
          job.name = pipeline_job_name
          job.project = project
        end

        job.visit!

        Page::Project::Job::Show.perform do |show|
          expect(show.output).to have_content(variable_custom_value)
        end
      end
    end
  end
end
