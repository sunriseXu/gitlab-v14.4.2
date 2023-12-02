# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User scrolls to deep-linked note' do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:comment_1) { create(:note_on_issue, noteable: issue, project: project, note: 'written first') }
  let_it_be(:comments) { create_list(:note_on_issue, 20, noteable: issue, project: project, note: 'spacer note') }

  context 'on issue page', :js do
    it 'on comment' do
      stub_feature_flags(gl_avatar_for_all_user_avatars: false)
      visit project_issue_path(project, issue, anchor: "note_#{comment_1.id}")

      wait_for_requests

      expect(first_comment).to have_content(comment_1.note)

      bottom_of_title = find('.issue-sticky-header.gl-fixed').evaluate_script("this.getBoundingClientRect().bottom;")
      top = first_comment.evaluate_script("this.getBoundingClientRect().top;")

      expect(top).to be_within(1).of(bottom_of_title)
    end
  end

  def all_comments
    all('.timeline > .note.timeline-entry')
  end

  def first_comment
    all_comments.first
  end
end
