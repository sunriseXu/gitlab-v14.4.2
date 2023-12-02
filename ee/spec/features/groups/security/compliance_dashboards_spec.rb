# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Compliance Dashboard', :js do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:project_2) { create(:project, :repository, :public, namespace: group) }

  shared_examples 'exports a merge commit-specific CSV' do
    it 'downloads a commit chain of custory report', :aggregate_failures do
      page.within('[data-testid="merge-commit-dropdown"]') do
        find('.dropdown-toggle').click

        requests = inspect_requests do
          page.within('.dropdown-menu') do
            find('input[name="commit_sha"]').set(merge_request.merge_commit_sha)
            find('button[type="submit"]').click
          end
        end

        csv_request = requests.find { |req| req.url.match(%r{.csv}) }

        expect(csv_request.response_headers['Content-Disposition']).to match(%r{.csv})
        expect(csv_request.response_headers['Content-Type']).to eq("text/csv; charset=utf-8")
        expect(csv_request.response_headers['Content-Transfer-Encoding']).to eq("binary")
        expect(csv_request.body).to match(%r{#{merge_request.merge_commit_sha}})
        expect(csv_request.body).not_to match(%r{#{merge_request_2.merge_commit_sha}})
      end
    end
  end

  before do
    stub_feature_flags(async_chain_of_custody_report: false)
    stub_licensed_features(group_level_compliance_dashboard: true)
    group.add_owner(user)
    sign_in(user)
    visit group_security_compliance_dashboard_path(group)
  end

  it 'shows the violations report table', :aggregate_failures do
    page.within('table') do
      expect(page).to have_content 'Severity'
      expect(page).to have_content 'Violation'
      expect(page).to have_content 'Merge request'
      expect(page).to have_content 'Date merged'
    end
  end

  context 'when there are no compliance violations' do
    it 'shows an empty state' do
      expect(page).to have_content('No violations found')
    end
  end

  context 'when there are merge requests' do
    let_it_be(:user_2) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, state: :merged, author: user, merge_commit_sha: 'b71a6483b96dc303b66fdcaa212d9db6b10591ce') }
    let_it_be(:merge_request_2) { create(:merge_request, source_project: project_2, state: :merged, author: user_2, merge_commit_sha: '24327319d067f4101cd3edd36d023ab5e49a8579') }

    context 'chain of custody report' do
      it_behaves_like 'exports a merge commit-specific CSV'
    end

    context 'and there is a compliance violation' do
      let_it_be(:violation) { create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request, violating_user: user) }
      let_it_be(:violation_2) { create(:compliance_violation, :approved_by_merge_request_author, severity_level: :medium, merge_request: merge_request_2, violating_user: user) }

      let(:merged_at) { 1.day.ago }

      before do
        merge_request.metrics.update!(merged_at: merged_at)
        merge_request_2.metrics.update!(merged_at: 7.days.ago)

        wait_for_requests
      end

      it 'shows the compliance violations with details', :aggregate_failures do
        expect(all('tbody > tr').count).to eq(2)

        expect(first_row).to have_content('High')
        expect(first_row).to have_content('Approved by committer')
        expect(first_row).to have_content(merge_request.title)
        expect(first_row).to have_content(merged_at.to_date.to_s)
      end

      it 'can sort the violations by clicking on a column header' do
        click_column_header 'Severity'

        expect(first_row).to have_content(merge_request_2.title)
      end

      it 'shows the correct user avatar popover content when the drawer is switched', :aggregate_failures do
        first_row.click
        drawer_user_avatar.hover

        within '.popover' do
          expect(page).to have_content(user.name)
          expect(page).to have_content(user.username)
        end

        second_row.click
        drawer_user_avatar.hover

        within '.popover' do
          expect(page).to have_content(user_2.name)
          expect(page).to have_content(user_2.username)
        end
      end

      context 'violations filter' do
        it 'can filter by date range' do
          set_date_range(7.days.ago.to_date, 6.days.ago.to_date)

          expect(page).to have_content(merge_request_2.title)
          expect(page).not_to have_content(merge_request.title)
        end

        it 'can filter by project id' do
          filter_by_project(merge_request_2.project)

          expect(page).to have_content(merge_request_2.title)
          expect(page).not_to have_content(merge_request.title)
        end
      end
    end
  end

  def first_row
    find('tbody tr', match: :first)
  end

  def second_row
    all('tbody tr')[1]
  end

  def drawer_user_avatar
    page.within('.gl-drawer') do
      first('.js-user-link')
    end
  end

  def set_date_range(start_date, end_date)
    page.within('[data-testid="violations-date-range-picker"]') do
      all('input')[0].set(start_date)
      all('input')[0].native.send_keys(:return)
      all('input')[1].set(end_date)
      all('input')[1].native.send_keys(:return)
    end
  end

  def filter_by_project(project)
    page.within('[data-testid="violations-project-dropdown"]') do
      find('.dropdown-toggle').click

      find('input[aria-label="Search"]').set(project.name)
      wait_for_requests

      find('.dropdown-item').click
      find('.dropdown-toggle').click
    end

    page.find('body').click
  end

  def click_column_header(name)
    page.within('thead') do
      find('div', text: name).click
      wait_for_requests
    end
  end
end
