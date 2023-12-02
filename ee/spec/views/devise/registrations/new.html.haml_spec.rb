# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/new' do
  let(:arkose_labs_api_key) { "api-key" }
  let(:arkose_labs_domain) { "domain" }

  subject { render(template: 'devise/registrations/new') }

  before do
    stub_devise

    allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return(arkose_labs_api_key)
    allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return(arkose_labs_domain)
  end

  it 'renders challenge container with the correct data attributes', :aggregate_failures do
    subject

    expect(rendered).to have_selector('#js-arkose-labs-challenge')
    expect(rendered).to have_selector("[data-api-key='#{arkose_labs_api_key}']")
    expect(rendered).to have_selector("[data-domain='#{arkose_labs_domain}']")
  end

  context 'when the :arkose_labs_signup_challenge feature flag is disabled' do
    before do
      stub_feature_flags(arkose_labs_signup_challenge: false)
    end

    it 'does not render challenge container', :aggregate_failures do
      subject

      expect(rendered).not_to have_selector('#js-arkose-labs-challenge')
      expect(rendered).not_to have_selector("[data-api-key='#{arkose_labs_api_key}']")
      expect(rendered).not_to have_selector("[data-domain='#{arkose_labs_domain}']")
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(build(:user))
    allow(view).to receive(:resource_name).and_return(:user)
  end
end
