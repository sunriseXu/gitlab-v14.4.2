# frozen_string_literal: true

module EE
  module Types
    module SubscriptionType
      extend ActiveSupport::Concern

      prepended do
        field :issuable_weight_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                        description: 'Triggered when the weight of an issuable is updated.'
      end
    end
  end
end
