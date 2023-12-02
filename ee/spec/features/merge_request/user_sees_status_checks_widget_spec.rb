# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees status checks widget', :js do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:check_pending) { create(:external_status_check, project: project) }
  let_it_be(:check_failed) { create(:external_status_check, project: project) }
  let_it_be(:check_passed) { create(:external_status_check, project: project) }

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:status_check_response_passed) { create(:status_check_response, external_status_check: check_passed, merge_request: merge_request, sha: merge_request.source_branch_sha, status: 'passed') }
  let_it_be(:status_check_response_failed) { create(:status_check_response, external_status_check: check_failed, merge_request: merge_request, sha: merge_request.source_branch_sha, status: 'failed') }

  shared_examples 'no status checks widget' do
    it 'does not show the widget' do
      expect(page).not_to have_selector('[data-test-id="mr-status-checks"]')
    end
  end

  before do
    stub_licensed_features(external_status_checks: true)
    stub_feature_flags(refactor_mr_widgets_extensions: false)
    stub_feature_flags(refactor_mr_widgets_extensions_user: false)
    stub_feature_flags(refactor_security_extension: false)
  end

  context 'user is authorized' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows the widget' do
      expect(page).to have_content('Status checks 1 failed, and 1 pending')
    end

    where(:check, :icon_class) do
      lazy { check_pending } | '.ci-status-icon-pending'
      lazy { check_passed } | '.ci-status-icon-success'
      lazy { check_failed } | '.ci-status-icon-failed'
    end

    with_them do
      it 'is rendered correctly', :aggregate_failures do
        within '[data-test-id="mr-status-checks"]' do
          click_button 'Expand'
        end

        within "[data-testid='mr-status-check-issue-#{check.id}']" do
          expect(page).to have_css(icon_class)
          expect(page).to have_content("#{check.name}: #{check.external_url}")
        end
      end
    end
  end

  context 'user is not logged in' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    it_behaves_like 'no status checks widget'
  end
end
