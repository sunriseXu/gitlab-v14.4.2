# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages merge pipelines option', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(merge_pipelines: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  it 'sees unchecked merge pipeline checkbox' do
    visit project_settings_merge_requests_path(project)

    expect(page.find('#project_merge_pipelines_enabled')).not_to be_checked
  end

  context 'when user enabled the checkbox' do
    before do
      visit project_settings_merge_requests_path(project)

      check('Enable merged results pipelines')
    end

    it 'sees enabled merge pipeline checkbox' do
      expect(page.find('#project_merge_pipelines_enabled')).to be_checked
    end
  end

  context 'when license is insufficient' do
    before do
      stub_licensed_features(merge_pipelines: false)
    end

    it 'does not see the checkbox' do
      expect(page).not_to have_css('#project_merge_pipelines_enabled')
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(merge_pipelines: false)
    end

    it 'does not see the checkbox' do
      expect(page).not_to have_css('#project_merge_pipelines_enabled')
    end
  end
end
