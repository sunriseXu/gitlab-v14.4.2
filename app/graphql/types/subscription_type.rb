# frozen_string_literal: true

module Types
  class SubscriptionType < ::Types::BaseObject
    graphql_name 'Subscription'

    field :issuable_assignees_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                       description: 'Triggered when the assignees of an issuable are updated.'

    field :issue_crm_contacts_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                       description: 'Triggered when the crm contacts of an issuable are updated.'

    field :issuable_title_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                   description: 'Triggered when the title of an issuable is updated.'

    field :issuable_labels_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                    description: 'Triggered when the labels of an issuable are updated.'

    field :issuable_dates_updated, subscription: Subscriptions::IssuableUpdated, null: true,
                                   description: 'Triggered when the due date or start date of an issuable is updated.'

    field :merge_request_reviewers_updated,
          subscription: Subscriptions::IssuableUpdated,
          null: true,
          description: 'Triggered when the reviewers of a merge request are updated.'
  end
end

Types::SubscriptionType.prepend_mod
