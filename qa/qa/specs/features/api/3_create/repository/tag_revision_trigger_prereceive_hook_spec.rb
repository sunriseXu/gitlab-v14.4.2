# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Prereceive hook', product_group: :source_code do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.initialize_with_readme = true
        end
      end

      context 'when creating a tag for a ref' do
        context 'when it triggers a prereceive hook configured with a custom error' do
          before do
            # The configuration test prereceive hook must match a specific naming pattern
            # In this test we create a project with a different name and then change the path.
            # Otherwise we wouldn't be able create any commits to be tagged due to the hook.
            project.change_path("project-reject-prereceive-#{SecureRandom.hex(8)}")
          end

          it 'returns a custom server hook error',
             :skip_live_env,
             except: { job: 'review-qa-*' },
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/369053' do
            expect { project.create_repository_tag('v1.2.3') }
              .to raise_error
                    .with_message(
                      /rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive/
                    )
          end
        end
      end
    end
  end
end
