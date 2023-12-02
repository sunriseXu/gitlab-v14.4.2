# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Leave group' do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  it 'guest leaves the group' do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'guest leaves the group by url param', :js do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group, leave: 1)

    accept_gl_confirm(button_text: 'Leave group')

    wait_for_all_requests
    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(group.users).not_to include(user)
  end

  it 'guest leaves the group as last member' do
    group.add_guest(user)

    visit group_path(group)
    click_link 'Leave group'

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'owner leaves the group if they are not the last owner' do
    group.add_owner(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'owner can not leave the group if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group)

    expect(page).not_to have_content 'Leave group'

    visit group_group_members_path(group)

    expect(members_table).not_to have_selector 'button[title="Leave"]'
  end

  it 'owner can not leave the group by url param if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group, leave: 1)

    expect(find('[data-testid="alert-danger"]')).to have_content 'You do not have permission to leave this group'
  end

  def left_group_message(group)
    "You left the \"#{group.name}\""
  end
end
