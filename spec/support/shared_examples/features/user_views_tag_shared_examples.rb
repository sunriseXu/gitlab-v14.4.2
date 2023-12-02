# frozen_string_literal: true

RSpec.shared_examples 'user views tag' do
  context 'when user views with the tag' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:tag_name) { "stable" }
    let!(:release) { create(:release, project: project, tag: tag_name, name: "ReleaseName") }

    before do
      project.add_developer(user)
      project.repository.add_tag(user, tag_name, project.default_branch_or_main)

      sign_in(user)
    end

    shared_examples 'shows tag' do
      it do
        visit tag_page

        expect(page).to have_content tag_name
        expect(page).to have_link("ReleaseName", href: project_release_path(project, release))
      end
    end

    it_behaves_like 'shows tag'

    context 'when tag name contains a slash' do
      let(:tag_name) { "stable/v0.1" }

      it_behaves_like 'shows tag'
    end
  end
end
