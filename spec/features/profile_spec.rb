# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile account page', :js do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'when I delete my account' do
    before do
      visit profile_account_path

      # Scroll page to the bottom to make Delete account button visible
      execute_script('window.scrollTo(0, document.body.scrollHeight)')
    end

    it { expect(page).to have_content('Delete account') }

    it 'does not immediately delete the account' do
      click_button 'Delete account'

      expect(User.exists?(user.id)).to be_truthy
    end

    context 'when user_destroy_with_limited_execution_time_worker is enabled' do
      it 'deletes user', :js, :sidekiq_inline do
        click_button 'Delete account'

        fill_in 'password', with: user.password

        page.within '.modal' do
          click_button 'Delete account'
        end

        expect(page).to have_content('Account scheduled for removal')
        expect(
          Users::GhostUserMigration.where(user: user,
                                          initiator_user: user)
        ).to be_exists
      end
    end

    context 'when user_destroy_with_limited_execution_time_worker is disabled' do
      before do
        stub_feature_flags(user_destroy_with_limited_execution_time_worker: false)
      end

      it 'deletes user', :js, :sidekiq_inline do
        click_button 'Delete account'

        fill_in 'password', with: user.password

        page.within '.modal' do
          click_button 'Delete account'
        end

        expect(page).to have_content('Account scheduled for removal')
        expect(User.exists?(user.id)).to be_falsy
      end
    end

    it 'shows invalid password flash message', :js do
      click_button 'Delete account'

      fill_in 'password', with: 'testing123'

      page.within '.modal' do
        click_button 'Delete account'
      end

      expect(page).to have_content('Invalid password')
    end

    it 'does not show delete button when user owns a group' do
      group = create(:group)
      group.add_owner(user)

      visit profile_account_path

      expect(page).not_to have_button('Delete account')
      expect(page).to have_content("Your account is currently an owner in these groups: #{group.name}")
    end
  end

  it 'allows resetting of feed token' do
    visit profile_personal_access_tokens_path

    previous_token = ''

    within('[data-testid="feed-token-container"]') do
      previous_token = find_field('Feed token').value

      click_link('reset this token')
    end

    accept_gl_confirm

    within('[data-testid="feed-token-container"]') do
      click_button('Click to reveal')

      expect(find_field('Feed token').value).not_to eq(previous_token)
    end
  end

  it 'allows resetting of incoming email token' do
    allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)

    visit profile_personal_access_tokens_path

    previous_token = ''

    within('[data-testid="incoming-email-token-container"]') do
      previous_token = find_field('Incoming email token').value

      click_link('reset this token')
    end

    accept_gl_confirm

    within('[data-testid="incoming-email-token-container"]') do
      click_button('Click to reveal')

      expect(find_field('Incoming email token').value).not_to eq(previous_token)
    end
  end

  describe 'when I change my username' do
    before do
      visit profile_account_path
    end

    it 'changes my username' do
      fill_in 'username-change-input', with: 'new-username'

      page.find('[data-testid="username-change-confirmation-modal"]').click

      page.within('.modal') do
        find('.js-modal-action-primary').click
      end

      expect(page).to have_content('new-username')
    end
  end
end
