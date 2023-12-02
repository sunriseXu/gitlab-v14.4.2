# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runners' do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when user opens runners page' do
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
    end

    it 'user can see a link with instructions on how to install GitLab Runner' do
      visit project_runners_path(project)

      expect(page).to have_link('Install GitLab Runner and ensure it\'s running.', href: "https://docs.gitlab.com/runner/install/")
    end
  end

  context 'when a project has enabled shared_runners' do
    let_it_be(:project) { create(:project) }

    before do
      project.add_maintainer(user)
    end

    context 'when a project_type runner is activated on the project' do
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      it 'user sees the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_content(project_runner.display_name)
        end

        click_on project_runner.short_sha

        expect(page).to have_content(project_runner.platform)
      end

      it 'user can pause and resume the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_link('Pause')
        end

        click_on 'Pause'

        within '.activated-specific-runners' do
          expect(page).to have_link('Resume')
        end

        click_on 'Resume'

        within '.activated-specific-runners' do
          expect(page).to have_link('Pause')
        end
      end

      it 'user removes an activated specific runner if this is last project for that runners' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          click_on 'Remove runner'
        end

        expect(page).not_to have_content(project_runner.display_name)
      end

      it 'user edits the runner to be protected' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          first('[data-testid="edit-runner-link"]').click
        end

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        before do
          project_runner.update!(tag_list: ['tag'])
        end

        it 'user edits runner not to run untagged jobs' do
          visit project_runners_path(project)

          within '.activated-specific-runners' do
            first('[data-testid="edit-runner-link"]').click
          end

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end

      context 'when a shared runner is activated on the project' do
        let!(:shared_runner) { create(:ci_runner, :instance) }

        it 'user sees CI/CD setting page' do
          visit project_runners_path(project)

          expect(page.find('.available-shared-runners')).to have_content(shared_runner.display_name)
        end
      end

      context 'when multiple runners are configured' do
        let!(:project_runner_2) { create(:ci_runner, :project, projects: [project]) }

        it 'adds pagination to the runner list' do
          stub_const('Projects::Settings::CiCdController::NUMBER_OF_RUNNERS_PER_PAGE', 1)

          visit project_runners_path(project)

          expect(find('.pagination')).not_to be_nil
        end
      end
    end

    context 'when a specific runner exists in another project' do
      let(:another_project) { create(:project) }
      let!(:project_runner) { create(:ci_runner, :project, projects: [another_project]) }

      before do
        another_project.add_maintainer(user)
      end

      it 'user enables and disables a specific runner' do
        visit project_runners_path(project)

        within '.available-specific-runners' do
          click_on 'Enable for this project'
        end

        expect(page.find('.activated-specific-runners')).to have_content(project_runner.display_name)

        within '.activated-specific-runners' do
          click_on 'Disable for this project'
        end

        expect(page.find('.available-specific-runners')).to have_content(project_runner.display_name)
      end
    end

    context 'shared runner text' do
      context 'when application settings have no shared_runners_text' do
        it 'user sees default shared runners description' do
          visit project_runners_path(project)

          page.within("[data-testid='shared-runners-description']") do
            expect(page).to have_content('The same shared runner executes code from multiple projects')
          end
        end
      end

      context 'when application settings have shared_runners_text' do
        let(:shared_runners_text) { 'custom **shared** runners description' }
        let(:shared_runners_html) { 'custom shared runners description' }

        before do
          stub_application_setting(shared_runners_text: shared_runners_text)
        end

        it 'user sees shared runners description' do
          visit project_runners_path(project)

          page.within("[data-testid='shared-runners-description']") do
            expect(page).not_to have_content('The same shared runner executes code from multiple projects')
            expect(page).to have_content(shared_runners_html)
          end
        end
      end

      context 'when application settings have an unsafe link in shared_runners_text' do
        let(:shared_runners_text) { '<a href="javascript:alert(\'xss\')">link</a>' }

        before do
          stub_application_setting(shared_runners_text: shared_runners_text)
        end

        it 'user sees no link' do
          visit project_runners_path(project)

          page.within("[data-testid='shared-runners-description']") do
            expect(page).to have_content('link')
            expect(page).not_to have_link('link')
          end
        end
      end

      context 'when application settings have an unsafe image in shared_runners_text' do
        let(:shared_runners_text) { '<img src="404.png" onerror="alert(\'xss\')"/>' }

        before do
          stub_application_setting(shared_runners_text: shared_runners_text)
        end

        it 'user sees image safely' do
          visit project_runners_path(project)

          page.within("[data-testid='shared-runners-description']") do
            expect(page).to have_css('img')
            expect(page).not_to have_css('img[onerror]')
          end
        end
      end
    end
  end

  context 'enable shared runners in project settings', :js do
    before do
      project.add_maintainer(user)

      visit project_runners_path(project)
    end

    context 'when a project has enabled shared_runners' do
      let(:project) { create(:project, shared_runners_enabled: true) }

      it 'shared runners toggle is on' do
        expect(page).to have_selector('[data-testid="toggle-shared-runners"]')
        expect(page).to have_selector('[data-testid="toggle-shared-runners"] .is-checked')
      end
    end

    context 'when a project has disabled shared_runners' do
      let(:project) { create(:project, shared_runners_enabled: false) }

      it 'shared runners toggle is off' do
        expect(page).not_to have_selector('[data-testid="toggle-shared-runners"] .is-checked')
      end
    end
  end

  context 'group runners in project settings' do
    before do
      project.add_maintainer(user)
    end

    let_it_be(:group) { create :group }
    let_it_be(:project) { create :project, group: group }

    context 'as project and group maintainer' do
      before do
        group.add_maintainer(user)
      end

      context 'project with a group but no group runner' do
        it 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).not_to have_content 'To register them, go to the group\'s Runners page.'
          expect(page).to have_content 'Ask your group owner to set up a group runner'
        end
      end
    end

    context 'as project maintainer and group owner' do
      before do
        group.add_owner(user)
      end

      context 'project with a group but no group runner' do
        it 'group runners are available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This group does not have any group runners yet.'

          expect(page).to have_content 'To register them, go to the group\'s Runners page.'
          expect(page).not_to have_content 'Ask your group owner to set up a group runner'
        end
      end
    end

    context 'as project maintainer' do
      context 'project without a group' do
        let(:project) { create :project }

        it 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This project does not belong to a group and cannot make use of group runners.'
        end
      end

      context 'with group project' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }

        context 'project with a group but no group runner' do
          it 'group runners are not available' do
            visit project_runners_path(project)

            expect(page).to have_content 'This group does not have any group runners yet.'

            expect(page).not_to have_content 'To register them, go to the group\'s Runners page.'
            expect(page).to have_content 'Ask your group owner to set up a group runner.'
          end
        end

        context 'project with a group and a group runner' do
          let_it_be(:ci_runner) do
            create(:ci_runner, :group, groups: [group], description: 'group-runner')
          end

          it 'group runners are available' do
            visit project_runners_path(project)

            expect(page).to have_content 'Available group runners: 1'
            expect(page).to have_content 'group-runner'
          end

          it 'group runners may be disabled for a project' do
            visit project_runners_path(project)

            click_on 'Disable group runners'

            expect(page).to have_content 'Enable group runners'
            expect(project.reload.group_runners_enabled).to be false

            click_on 'Enable group runners'

            expect(page).to have_content 'Disable group runners'
            expect(project.reload.group_runners_enabled).to be true
          end
        end
      end
    end
  end
end
