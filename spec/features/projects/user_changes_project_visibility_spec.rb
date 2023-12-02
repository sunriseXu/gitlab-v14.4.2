# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User changes public project visibility', :js do
  include ProjectForksHelper

  shared_examples 'changing visibility to private' do
    it 'requires confirmation' do
      visibility_select = first('.project-feature-controls .select-control')
      visibility_select.select('Private')

      page.within('#js-shared-permissions') do
        click_button 'Save changes'
      end

      fill_in 'confirm_name_input', with: project.path_with_namespace

      page.within '.modal' do
        click_button 'Reduce project visibility'
      end

      wait_for_requests

      expect(project.reload).to be_private
    end
  end

  shared_examples 'does not require confirmation' do
    it 'saves without confirmation' do
      visibility_select = first('.project-feature-controls .select-control')
      visibility_select.select('Private')

      page.within('#js-shared-permissions') do
        click_button 'Save changes'
      end

      wait_for_requests

      expect(project.reload).to be_private
    end
  end

  context 'when the project has forks' do
    before do
      fork_project(project, project.first_owner)

      sign_in(project.first_owner)

      visit edit_project_path(project)
    end

    context 'when a project is public' do
      let(:project) { create(:project, :empty_repo, :public) }

      it_behaves_like 'changing visibility to private'
    end

    context 'when the project is internal' do
      let(:project) { create(:project, :empty_repo, :internal) }

      it_behaves_like 'changing visibility to private'
    end

    context 'when the visibility level is untouched' do
      let(:project) { create(:project, :empty_repo, :public) }

      it 'saves without confirmation' do
        expect(page).to have_selector('.js-emails-disabled', visible: true)
        find('.js-emails-disabled input[type="checkbox"]').click

        page.within('#js-shared-permissions') do
          click_button 'Save changes'
        end

        wait_for_requests

        expect(project.reload).to be_public
      end
    end
  end

  context 'when the project is not forked' do
    let(:project) { create(:project, :empty_repo, :public) }

    before do
      sign_in(project.first_owner)

      visit edit_project_path(project)
    end

    it_behaves_like 'does not require confirmation'
  end

  context 'with unlink_fork_network_upon_visibility_decrease = false' do
    let(:project) { create(:project, :empty_repo, :public) }

    before do
      stub_feature_flags(unlink_fork_network_upon_visibility_decrease: false)

      fork_project(project, project.first_owner)

      sign_in(project.first_owner)

      visit edit_project_path(project)
    end

    it_behaves_like 'does not require confirmation'
  end
end
