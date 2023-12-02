# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::MergeRequestLink do
  describe 'associations and fields' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to belong_to(:merge_request) }
  end
end
