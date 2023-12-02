# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StateTransition, type: :model do
  let_it_be(:vulnerability) { create(:vulnerability) }

  subject { create(:vulnerability_state_transitions, vulnerability: vulnerability) }

  describe 'associations' do
    it { is_expected.to belong_to(:vulnerability) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:vulnerability_id) }
    it { is_expected.to validate_presence_of(:from_state) }
    it { is_expected.to validate_presence_of(:to_state) }
  end

  describe 'enums' do
    let(:vulnerability_states) do
      ::Enums::Vulnerability.vulnerability_states
    end

    it { is_expected.to define_enum_for(:from_state).with_values(**vulnerability_states).with_prefix }
    it { is_expected.to define_enum_for(:to_state).with_values(**vulnerability_states).with_prefix }
  end
end
