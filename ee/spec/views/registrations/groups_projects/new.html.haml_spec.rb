# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/groups_projects/new' do
  let(:google_tag_manager_id) { 'GTM-WWKMTWS' }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  before do
    assign(:group, group)
    assign(:project, project)
    stub_config(extra:
                  {
                    google_tag_manager_id: google_tag_manager_id,
                    google_tag_manager_nonce_id: google_tag_manager_id
                  })
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:import_sources_enabled?).and_return(false)
  end

  context 'when Google Tag Manager is enabled' do
    before do
      allow(view).to receive(:google_tag_manager_enabled?).and_return(true)
      render
    end

    subject { rendered }

    it 'contains a Google Tag Manager tag' do
      is_expected.to match(/www.googletagmanager.com/)
    end
  end

  context 'when Google Tag Manager is disabled' do
    before do
      allow(view).to receive(:google_tag_manager_enabled?).and_return(false)
      render
    end

    subject { rendered }

    it 'does not contain a Google Tag Manager tag' do
      is_expected.not_to match(/www.googletagmanager.com/)
    end
  end

  describe 'expected DOM elements' do
    before do
      render
    end

    subject { rendered }

    it 'contains js-groups-projects-form class' do
      is_expected.to have_css('.js-groups-projects-form')
    end
  end
end
