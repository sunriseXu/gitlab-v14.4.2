# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :requires_admin, :skip_live_env, except: { job: 'review-qa-*' } do
    describe 'Jenkins integration' do
      let(:jenkins_server) { Service::DockerRun::Jenkins.new }

      let(:jenkins_client) do
        Vendor::Jenkins::Client.new(
          jenkins_server.host_name,
          port: jenkins_server.port,
          user: Runtime::Env.jenkins_admin_username,
          password: Runtime::Env.jenkins_admin_password
        )
      end

      let(:jenkins_project_name) { "gitlab_jenkins_#{SecureRandom.hex(5)}" }

      let(:connection_name) { 'gitlab-connection' }

      let(:project_name) { "project_with_jenkins_#{SecureRandom.hex(4)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = project_name
          project.initialize_with_readme = true
          project.auto_devops_enabled = false
        end
      end

      let(:access_token) do
        Runtime::Env.personal_access_token ||= fabricate_access_token
      end

      before do
        toggle_local_requests(true)
        jenkins_server.register!

        Support::Waiter.wait_until(max_duration: 30, reload_page: false, retry_on_exception: true) do
          jenkins_client.ready?
        end

        configure_gitlab_jenkins
      end

      after do
        jenkins_server&.remove!
        toggle_local_requests(false)
      end

      it 'integrates and displays build status for MR pipeline in GitLab', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347788' do
        setup_project_integration

        jenkins_integration = project.find_integration('jenkins')
        expect(jenkins_integration).not_to be(nil), 'Jenkins integration did not save'
        expect(jenkins_integration[:active]).to be(true), 'Jenkins integration is not active'

        job = create_jenkins_job

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.new_branch = false
          push.file_name = "file_#{SecureRandom.hex(4)}.txt"
        end

        Support::Waiter.wait_until(max_duration: 60, raise_on_failure: false, reload_page: false) do
          job.status == :success
        end

        expect(job.status).to eql(:success), "Build failed or is not found: #{job.log}"

        project.visit!

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_build('jenkins', status: :success, wait: 15)
        end
      end

      private

      def setup_project_integration
        login_to_gitlab

        project.visit!

        Page::Project::Menu.perform(&:click_project)
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_jenkins_ci_link)

        QA::Page::Project::Settings::Services::Jenkins.perform do |jenkins|
          jenkins.setup_service_with(
            jenkins_url: patch_host_name(jenkins_server.host_address, 'jenkins-server'),
            project_name: jenkins_project_name,
            username: jenkins_server.username,
            password: jenkins_server.password
          )
        end
      end

      def login_to_gitlab
        Flow::Login.sign_in
      end

      def fabricate_access_token
        login_to_gitlab

        token = Resource::PersonalAccessToken.fabricate!.token
        Page::Main::Menu.perform(&:sign_out)
        token
      end

      def create_jenkins_job
        jenkins_client.create_job jenkins_project_name do |job|
          job.gitlab_connection = connection_name
          job.description = 'Just a job'
          job.repo_url = patch_host_name(project.repository_http_location.git_uri, 'gitlab')
          job.shell_command = 'sleep 5'
        end
      end

      def configure_gitlab_jenkins
        jenkins_client.configure_gitlab_plugin(
          patch_host_name(Runtime::Scenario.gitlab_address, 'gitlab'),
          connection_name: connection_name,
          access_token: access_token,
          read_timeout: 20,
          connection_timeout: 10
        )
      end

      def patch_host_name(host_name, container_name)
        return host_name unless host_name.include?('localhost')

        ip_address = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{container_name}`.strip
        host_name.gsub('localhost', ip_address)
      end

      def toggle_local_requests(on)
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: on)
      end
    end
  end
end
