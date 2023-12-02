# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :registry, only: { pipeline: :main } do
    describe 'Dependency Proxy' do
      using RSpec::Parameterized::TableSyntax
      include Support::Helpers::MaskToken

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'dependency-proxy-project'
          project.visibility = :private
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:group_deploy_token) do
        Resource::GroupDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'dp-group-deploy-token'
          deploy_token.group = project.group
          deploy_token.scopes = %w[
            read_registry
            write_registry
          ]
        end
      end

      let(:personal_access_token) { Runtime::Env.personal_access_token }

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }
      let(:dependency_proxy_url) { "#{gitlab_host_with_port}/#{project.group.full_path}/dependency_proxy/containers" }
      let(:image_sha) { 'alpine@sha256:c3d45491770c51da4ef58318e3714da686bc7165338b7ab5ac758e75c7455efb' }

      before do
        Flow::Login.sign_in

        project.group.visit!

        Page::Group::Menu.perform(&:go_to_package_settings)

        Page::Group::Settings::PackageRegistries.perform do |index|
          expect(index).to have_dependency_proxy_enabled
        end
      end

      after do
        project.remove_via_api!
        runner.remove_via_api!
      end

      where do
        {
          'using docker:18.09.9 and a personal access token' => {
            docker_client_version: 'docker:18.09.9',
            authentication_token_type: :personal_access_token,
            token_name: 'Personal Access Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370195'
          },
          'using docker:18.09.9 and a group deploy token' => {
            docker_client_version: 'docker:18.09.9',
            authentication_token_type: :group_deploy_token,
            token_name: 'Deploy Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370196'
          },
          'using docker:18.09.9 and a ci job token' => {
            docker_client_version: 'docker:18.09.9',
            authentication_token_type: :ci_job_token,
            token_name: 'Job Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370198'
          },
          'using docker:19.03.12 and a personal access token' => {
            docker_client_version: 'docker:19.03.12',
            authentication_token_type: :personal_access_token,
            token_name: 'Personal Access Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370189'
          },
          'using docker:19.03.12 and a group deploy token' => {
            docker_client_version: 'docker:19.03.12',
            authentication_token_type: :group_deploy_token,
            token_name: 'Deploy Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370190'
          },
          'using docker:19.03.12 and a ci job token' => {
            docker_client_version: 'docker:19.03.12',
            authentication_token_type: :ci_job_token,
            token_name: 'Job Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370191'
          },
          'using docker:20.10 and a personal access token' => {
            docker_client_version: 'docker:20.10',
            authentication_token_type: :personal_access_token,
            token_name: 'Personal Access Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370192'
          },
          'using docker:20.10 and a group deploy token' => {
            docker_client_version: 'docker:20.10',
            authentication_token_type: :group_deploy_token,
            token_name: 'Deploy Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370193'
          },
          'using docker:20.10 and a ci job token' => {
            docker_client_version: 'docker:20.10',
            authentication_token_type: :ci_job_token,
            token_name: 'Job Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370194'
          }
        }
      end

      with_them do
        let(:auth_token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
          when :group_deploy_token
            use_group_ci_variable(
              name: "GROUP_DEPLOY_TOKEN_#{group_deploy_token.id}",
              value: group_deploy_token.token,
              group: project.group
            )
          when :ci_job_token
            '$CI_JOB_TOKEN'
          end
        end

        let(:auth_user) do
          case authentication_token_type
          when :personal_access_token
            "$CI_REGISTRY_USER"
          when :group_deploy_token
            "\"#{group_deploy_token.username}\""
          when :ci_job_token
            'gitlab-ci-token'
          end
        end

        it "pulls an image using the dependency proxy", testcase: params[:testcase] do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content:
                                      <<~YAML
                                        dependency-proxy-pull-test:
                                          image: "#{docker_client_version}"
                                          services:
                                          - name: "#{docker_client_version}-dind"
                                            command: ["--insecure-registry=gitlab.test:80"]
                                          before_script:
                                            - apk add curl jq grep
                                            - docker login -u #{auth_user} -p #{auth_token} gitlab.test:80
                                          script:
                                            - docker pull #{dependency_proxy_url}/#{image_sha}
                                            - TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token)
                                            - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                            - docker pull #{dependency_proxy_url}/#{image_sha}
                                            - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                          tags:
                                          - "runner-for-#{project.name}"
                                      YAML
                              }])
            end
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('dependency-proxy-pull-test')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_dependency_proxy)

          Page::Group::DependencyProxy.perform do |index|
            expect(index).to have_blob_count("Contains 1 blobs of images")
          end
        end
      end
    end
  end
end
