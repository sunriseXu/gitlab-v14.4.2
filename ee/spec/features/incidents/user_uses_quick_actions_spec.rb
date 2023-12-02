# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incidents > User uses EE quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  describe 'incident-only commands' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue, reload: true) { create(:incident, project: project) }

    before do
      project.add_developer(user)
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    after do
      wait_for_requests
    end

    it_behaves_like 'zoom quick actions ee'
  end
end
