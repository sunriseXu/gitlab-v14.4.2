# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Personal Access Tokens', :js do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:pat_create_service) { double('PersonalAccessTokens::CreateService', execute: ServiceResponse.error(message: 'error', payload: { personal_access_token: PersonalAccessToken.new })) }

  def active_personal_access_tokens
    find("[data-testid='active-tokens']")
  end

  def created_personal_access_token
    find_field('new-access-token').value
  end

  def feed_token_description
    "Your feed token authenticates you when your RSS reader loads a personalized RSS feed or when your calendar application loads a personalized calendar. It is visible in those feed URLs."
  end

  before do
    sign_in(user)
  end

  describe "token creation" do
    it "allows creation of a personal access token" do
      name = 'My PAT'

      visit profile_personal_access_tokens_path
      fill_in "Token name", with: name

      # Set date to 1st of next month
      find_field("Expiration date").click
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "read_api"
      check "read_user"

      click_on "Create personal access token"
      wait_for_all_requests

      expect(active_personal_access_tokens).to have_text(name)
      expect(active_personal_access_tokens).to have_text('in')
      expect(active_personal_access_tokens).to have_text('read_api')
      expect(active_personal_access_tokens).to have_text('read_user')
      expect(created_personal_access_token).not_to be_empty
    end

    context "when creation fails" do
      it "displays an error message" do
        number_tokens_before = PersonalAccessToken.count
        visit profile_personal_access_tokens_path
        fill_in "Token name", with: 'My PAT'

        click_on "Create personal access token"
        wait_for_all_requests

        expect(number_tokens_before).to equal(PersonalAccessToken.count)
        expect(page).to have_content(_("Scopes can't be blank"))
        expect(page).not_to have_selector("[data-testid='new-access-tokens']")
      end
    end
  end

  describe 'active tokens' do
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it 'only shows personal access tokens' do
      visit profile_personal_access_tokens_path

      expect(active_personal_access_tokens).to have_text(personal_access_token.name)
      expect(active_personal_access_tokens).not_to have_text(impersonation_token.name)
    end

    context 'when User#time_display_relative is false' do
      before do
        user.update!(time_display_relative: false)
      end

      it 'shows absolute times for expires_at' do
        visit profile_personal_access_tokens_path

        expect(active_personal_access_tokens).to have_text(PersonalAccessToken.last.expires_at.strftime('%b %-d'))
      end
    end
  end

  describe "inactive tokens" do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it "allows revocation of an active token" do
      visit profile_personal_access_tokens_path
      accept_gl_confirm(button_text: 'Revoke') { click_on "Revoke" }

      expect(active_personal_access_tokens).to have_text("This user has no active personal access tokens.")
    end

    it "removes expired tokens from 'active' section" do
      personal_access_token.update!(expires_at: 5.days.ago)
      visit profile_personal_access_tokens_path

      expect(active_personal_access_tokens).to have_text("This user has no active personal access tokens.")
    end

    context "when revocation fails" do
      it "displays an error message" do
        allow_next_instance_of(PersonalAccessTokens::RevokeService) do |instance|
          allow(instance).to receive(:revocation_permitted?).and_return(false)
        end
        visit profile_personal_access_tokens_path

        accept_gl_confirm(button_text: "Revoke") { click_on "Revoke" }
        expect(active_personal_access_tokens).to have_text(personal_access_token.name)
      end
    end
  end

  describe "feed token" do
    context "when enabled" do
      it "displays feed token" do
        allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(false)
        visit profile_personal_access_tokens_path

        within('[data-testid="feed-token-container"]') do
          click_button('Click to reveal')

          expect(page).to have_field('Feed token', with: user.feed_token)
          expect(page).to have_content(feed_token_description)
        end
      end
    end

    context "when disabled" do
      it "does not display feed token" do
        allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(true)
        visit profile_personal_access_tokens_path

        expect(page).not_to have_content(feed_token_description)
        expect(page).not_to have_field('Feed token')
      end
    end
  end

  it "prefills token details" do
    name = 'My PAT'
    scopes = 'api,read_user'

    visit profile_personal_access_tokens_path({ name: name, scopes: scopes })

    expect(page).to have_field("Token name", with: name)
    expect(find("#personal_access_token_scopes_api")).to be_checked
    expect(find("#personal_access_token_scopes_read_user")).to be_checked
  end
end
