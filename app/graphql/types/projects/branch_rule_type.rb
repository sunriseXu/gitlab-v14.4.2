# frozen_string_literal: true

module Types
  module Projects
    class BranchRuleType < BaseObject
      graphql_name 'BranchRule'
      description 'List of branch rules for a project, grouped by branch name.'
      accepts ::ProtectedBranch
      authorize :read_protected_branch

      field :name,
            type: GraphQL::Types::String,
            null: false,
            description: 'Branch name, with wildcards, for the branch rules.'

      field :branch_protection,
            type: Types::BranchRules::BranchProtectionType,
            null: false,
            description: 'Branch protections configured for this branch rule.',
            method: :itself

      field :created_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was created.'

      field :updated_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was last updated.'
    end
  end
end
