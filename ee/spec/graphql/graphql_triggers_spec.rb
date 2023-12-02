# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers do
  describe '.issuable_weight_updated' do
    let(:work_item) { create(:work_item) }

    it 'triggers the issuableWeightUpdated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableWeightUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      ::GraphqlTriggers.issuable_weight_updated(work_item)
    end
  end
end
