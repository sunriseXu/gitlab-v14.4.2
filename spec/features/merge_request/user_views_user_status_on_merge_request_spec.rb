# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Merge request > View user status' do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project, author: create(:user))
  end

  before do
    stub_feature_flags(remove_user_attributes_projects: false)
  end

  subject { visit merge_request_path(merge_request) }

  context 'for notes', :js do
    describe 'the status of the author of a note on a merge request' do
      let(:note) { create(:note, noteable: merge_request, project: project, author: create(:user)) }

      it_behaves_like 'showing user status' do
        let(:user_with_status) { note.author }
      end
    end

    describe 'the status of the author of a diff note on a merge request' do
      let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, author: create(:user)) }

      it_behaves_like 'showing user status' do
        let(:user_with_status) { note.author }
      end
    end
  end
end
