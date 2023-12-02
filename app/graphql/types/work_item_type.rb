# frozen_string_literal: true

module Types
  class WorkItemType < BaseObject
    graphql_name 'WorkItem'

    authorize :read_work_item

    field :closed_at, Types::TimeType, null: true,
                                       description: 'Timestamp of when the work item was closed.'
    field :confidential, GraphQL::Types::Boolean, null: false,
                                                  description: 'Indicates the work item is confidential.'
    field :created_at, Types::TimeType, null: false,
                                        description: 'Timestamp of when the work item was created.'
    field :description, GraphQL::Types::String, null: true,
                                                description: 'Description of the work item.'
    field :id, Types::GlobalIDType[::WorkItem], null: false,
                                                description: 'Global ID of the work item.'
    field :iid, GraphQL::Types::ID, null: false,
                                    description: 'Internal ID of the work item.'
    field :lock_version,
          GraphQL::Types::Int,
          null: false,
          description: 'Lock version of the work item. Incremented each time the work item is updated.'
    field :project, Types::ProjectType, null: false,
                                        description: 'Project the work item belongs to.',
                                        alpha: { milestone: '15.3' }
    field :state, WorkItemStateEnum, null: false,
                                     description: 'State of the work item.'
    field :title, GraphQL::Types::String, null: false,
                                          description: 'Title of the work item.'
    field :updated_at, Types::TimeType, null: false,
                                        description: 'Timestamp of when the work item was last updated.'
    field :widgets,
          [Types::WorkItems::WidgetInterface],
          null: true,
          description: 'Collection of widgets that belong to the work item.'
    field :work_item_type, Types::WorkItems::TypeType, null: false,
                                                       description: 'Type assigned to the work item.'

    markdown_field :title_html, null: true
    markdown_field :description_html, null: true

    expose_permissions Types::PermissionTypes::WorkItem
  end
end
