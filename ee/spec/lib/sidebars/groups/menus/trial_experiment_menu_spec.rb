# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::TrialExperimentMenu, :saas do
  it_behaves_like 'trial experiment menu items' do
    let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  end
end
