# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/index.html.haml' do
  include Devise::Test::ControllerHelpers
  include StubVersion

  before do
    counts = Admin::DashboardController::COUNTED_ITEMS.each_with_object({}) do |item, hash|
      hash[item] = 100
    end

    assign(:counts, counts)
    assign(:projects, create_list(:project, 1))
    assign(:users, create_list(:user, 1))
    assign(:groups, create_list(:group, 1))

    allow(view).to receive(:admin?).and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  it "shows version of GitLab Workhorse" do
    render

    expect(rendered).to have_content 'GitLab Workhorse'
    expect(rendered).to have_content Gitlab::Workhorse.version
  end

  it "includes revision of GitLab for pre VERSION" do
    stub_version('13.11.0-pre', 'abcdefg')

    render

    expect(rendered).to have_content "13.11.0-pre abcdefg"
  end

  it 'shows the tag for GitLab version' do
    stub_version('13.11.0', 'abcdefg')

    render

    expect(rendered).to have_content "13.11.0"
    expect(rendered).not_to have_content "abcdefg"
  end

  it 'does not include license breakdown' do
    render

    expect(rendered).not_to have_content "Users in License"
    expect(rendered).not_to have_content "Billable Users"
    expect(rendered).not_to have_content "Maximum Users"
    expect(rendered).not_to have_content "Users over License"
  end

  describe 'when show_version_check? is true' do
    before do
      allow(view).to receive(:show_version_check?).and_return(true)
      render
    end

    it 'renders the version check badge' do
      expect(rendered).to have_selector('.js-gitlab-version-check')
    end
  end

  describe 'GitLab KAS' do
    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(enabled)
      allow(Gitlab::Kas).to receive(:version).and_return('kas-1.2.3')
    end

    context 'KAS enabled' do
      let(:enabled) { true }

      it 'includes KAS version' do
        render

        expect(rendered).to have_content('GitLab KAS')
        expect(rendered).to have_content('kas-1.2.3')
      end
    end

    context 'KAS disabled' do
      let(:enabled) { false }

      it 'does not include KAS version' do
        render

        expect(rendered).not_to have_content('GitLab KAS')
        expect(rendered).not_to have_content('kas-1.2.3')
      end
    end
  end
end
