# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a merge request', :js do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(remove_user_attributes_projects: false)
    project.add_maintainer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'adds a comment' do
    page.within('.js-main-target-form') do
      fill_in('note[note]', with: '# Comment with a header')
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note') do
      expect(page).to have_content('Comment with a header')
      expect(page).not_to have_css('#comment-with-a-header')
    end
  end

  it 'replys to a new comment' do
    page.within('.js-main-target-form') do
      fill_in('note[note]', with: 'comment 1')
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note') do
      click_button('Reply to comment')

      fill_in('note[note]', with: 'comment 2')
      click_button('Add comment now')
    end

    wait_for_requests

    # Test that the discussion doesn't get auto-resolved
    expect(page).to have_button('Resolve thread')
  end

  array = [':', '@', '#', '%', '!', '~', '$', '[contact:']
  array.each do |x|
    it 'handles esc key correctly when atwho is active' do
      page.within('.js-main-target-form') do
        fill_in('note[note]', with: 'comment 1')
        click_button('Comment')
      end

      wait_for_requests

      page.within('.note') do
        click_button('Reply to comment')
        fill_in('note[note]', with: x)
        send_keys :escape
      end

      wait_for_requests
      expect(page.html).not_to include('Are you sure you want to cancel creating this comment?')
    end
  end

  it 'handles esc key correctly when atwho is not active' do
    page.within('.js-main-target-form') do
      fill_in('note[note]', with: 'comment 1')
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note') do
      click_button('Reply to comment')
      fill_in('note[note]', with: 'comment 2')
      send_keys :escape
    end

    wait_for_requests
    expect(page.html).to include('Are you sure you want to cancel creating this comment?')
  end

  it 'loads new comment' do
    # Add new comment in background in order to check
    # if it's going to be loaded automatically for current user.
    create(:diff_note_on_merge_request, project: project, noteable: merge_request, author: user, note: 'Line is wrong')
    # Trigger a refresh of notes.
    execute_script("$(document).trigger('visibilitychange');")
    wait_for_requests

    page.within('.notes .discussion') do
      expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
      expect(page).to have_content(sample_commit.line_code_path)
      expect(page).to have_content('Line is wrong')
    end

    page.within('.notes-tab .badge') do
      expect(page).to have_content('1')
    end
  end
end
