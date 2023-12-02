# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User interacts with project stars' do
  let(:project) { create(:project, :public, :repository) }

  context 'when user is signed in', :js do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      visit(project_path(project))
    end

    it 'toggles the star' do
      star_project

      expect(page).to have_css('.star-count', text: 1)

      unstar_project

      expect(page).to have_css('.star-count', text: 0)
    end

    it 'validates starring a project' do
      project.add_owner(user)

      star_project

      visit(dashboard_projects_path)

      expect(page).to have_css('.stars', text: 1)
    end

    it 'validates un-starring a project' do
      project.add_owner(user)

      star_project

      unstar_project

      visit(dashboard_projects_path)

      expect(page).to have_css('.stars', text: 0)
    end
  end

  context 'when user is not signed in' do
    before do
      visit(project_path(project))
    end

    it 'does not allow to star a project' do
      expect(page).not_to have_content('.toggle-star')

      find('.star-btn').click

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end
  end
end

private

def star_project
  click_button(_('Star'))
  wait_for_requests
end

def unstar_project
  click_button(_('Unstar'))
  wait_for_requests
end
