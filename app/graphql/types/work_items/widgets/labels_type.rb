# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class LabelsType < BaseObject
        graphql_name 'WorkItemWidgetLabels'
        description 'Represents the labels widget'

        implements Types::WorkItems::WidgetInterface

        field :labels, Types::LabelType.connection_type,
          null: true,
          description: 'Labels assigned to the work item.'

        field :allows_scoped_labels, GraphQL::Types::Boolean,
          null: true,
          method: :allows_scoped_labels?,
          description: 'Indicates whether a scoped label is allowed.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
