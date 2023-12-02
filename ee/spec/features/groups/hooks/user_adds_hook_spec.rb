# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User adds hook" do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:url) { "http://example.org" }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it "adds new hook" do
    fill_in("hook_url", with: url)

    expect { click_button("Add webhook") }.to change(GroupHook, :count).by(1)
    expect(page).to have_current_path group_hooks_path(group), ignore_query: true
    expect(page).to have_content(url)
  end
end
