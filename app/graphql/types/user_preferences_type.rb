# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Only used to render the current user's own preferences
  class UserPreferencesType < BaseObject
    graphql_name 'UserPreferences'

    field :issues_sort, Types::IssueSortEnum,
      description: 'Sort order for issue lists.',
      null: true

    def issues_sort
      object.issues_sort.to_sym
    end
  end
end
