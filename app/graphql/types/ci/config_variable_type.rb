# frozen_string_literal: true

module Types
  module Ci
    class ConfigVariableType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'CiConfigVariable'
      description 'CI/CD config variables.'

      field :key, GraphQL::Types::String,
            null: true,
            description: 'Name of the variable.'

      field :description, GraphQL::Types::String,
            null: true,
            description: 'Description for the CI/CD config variable.'

      field :value, GraphQL::Types::String,
            null: true,
            description: 'Value of the variable.'
    end
  end
end
