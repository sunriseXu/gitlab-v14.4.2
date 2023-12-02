# frozen_string_literal: true

module Types
  class EpicType < BaseObject
    graphql_name 'Epic'
    description 'Represents an epic'

    connection_type_class(Types::CountableConnectionType)

    include ::Gitlab::Graphql::Aggregations::Epics::Constants

    accepts ::Epic
    authorize :read_epic

    expose_permissions Types::PermissionTypes::Epic

    present_using EpicPresenter

    implements(Types::Notes::NoteableInterface)
    implements(Types::CurrentUserTodos)
    implements(Types::EventableType)
    implements(Types::TodoableInterface)

    field :confidential, GraphQL::Types::Boolean,
      null: true, description: 'Indicates if the epic is confidential.'

    field :description, GraphQL::Types::String,
      null: true, description: 'Description of the epic.'

    field :id, GraphQL::Types::ID, null: false, description: 'ID of the epic.'

    field :iid, GraphQL::Types::ID, null: false, description: 'Internal ID of the epic.'

    field :state, EpicStateEnum, null: false, description: 'State of the epic.'

    field :title, GraphQL::Types::String, null: true, description: 'Title of the epic.'

    field :author, Types::UserType, null: false, description: 'Author of the epic.'

    field :group, 'Types::GroupType', null: false, description: 'Group to which the epic belongs.'

    field :parent, Types::EpicType, null: true, description: 'Parent epic of the epic.'

    field :start_date, Types::TimeType, null: true, description: 'Start date of the epic.'

    field :start_date_fixed, Types::TimeType,
      null: true, authorize: :admin_epic, description: 'Fixed start date of the epic.'

    field :start_date_from_inherited_source, Types::TimeType,
      null: true, authorize: :admin_epic,
      description: 'Inherited start date of the epic from child epics or milestones.'

    field :start_date_from_milestones, Types::TimeType,
      null: true, authorize: :admin_epic,
      description: 'Inherited start date of the epic from milestones.'

    field :start_date_is_fixed, GraphQL::Types::Boolean,
      null: true, method: :start_date_is_fixed?, authorize: :admin_epic,
      description: 'Indicates if the start date has been manually set.'

    field :due_date, Types::TimeType, null: true, description: 'Due date of the epic.'

    field :due_date_fixed, Types::TimeType,
      null: true, authorize: :admin_epic, description: 'Fixed due date of the epic.'

    field :due_date_from_inherited_source, Types::TimeType,
      null: true, authorize: :admin_epic,
      description: 'Inherited due date of the epic from child epics or milestones.'

    field :due_date_from_milestones, Types::TimeType,
      null: true, authorize: :admin_epic,
      description: 'Inherited due date of the epic from milestones.'

    field :due_date_is_fixed, GraphQL::Types::Boolean,
      null: true, method: :due_date_is_fixed?, authorize: :admin_epic,
      description: 'Indicates if the due date has been manually set.'

    field :downvotes, GraphQL::Types::Int,
      null: false, description: 'Number of downvotes the epic has received.'

    field :upvotes, GraphQL::Types::Int,
      null: false, description: 'Number of upvotes the epic has received.'

    field :user_discussions_count, GraphQL::Types::Int,
      null: false, resolver: Resolvers::UserDiscussionsCountResolver,
      description: 'Number of user discussions in the epic.'

    field :user_notes_count, GraphQL::Types::Int,
      null: false, resolver: Resolvers::UserNotesCountResolver,
      description: 'Number of user notes of the epic.'

    field :closed_at, Types::TimeType,
        null: true, description: 'Timestamp of when the epic was closed.'

    field :created_at, Types::TimeType,
        null: true, description: 'Timestamp of when the epic was created.'

    field :updated_at, Types::TimeType,
        null: true, description: 'Timestamp of when the epic was updated.'

    field :children, ::Types::EpicType.connection_type,
      null: true, resolver: ::Resolvers::EpicsResolver,
      description: 'Children (sub-epics) of the epic.'

    field :labels, Types::LabelType.connection_type,
        null: true, description: 'Labels assigned to the epic.'

    field :has_children, GraphQL::Types::Boolean,
        null: false, description: 'Indicates if the epic has children.'

    field :has_issues, GraphQL::Types::Boolean,
        null: false, description: 'Indicates if the epic has direct issues.'

    field :has_parent, GraphQL::Types::Boolean,
        null: false, method: :has_parent?, description: 'Indicates if the epic has a parent epic.'

    field :web_path, GraphQL::Types::String,
        null: false, method: :group_epic_path, description: 'Web path of the epic.'

    field :web_url, GraphQL::Types::String,
        null: false, method: :group_epic_url, description: 'Web URL of the epic.'

    field :relation_path, GraphQL::Types::String,
        null: true, method: :group_epic_link_path,
        description: 'URI path of the epic-issue relationship.'

    field :relative_position, GraphQL::Types::Int,
        null: true, description: 'Relative position of the epic in the epic tree.'

    field :reference, GraphQL::Types::String,
      null: false, method: :epic_reference,
      description: 'Internal reference of the epic. Returned in shortened format by default.' do
        argument :full, GraphQL::Types::Boolean,
          required: false, default_value: false,
          description: 'Indicates if the reference should be returned in full.'
      end

    field :participants, Types::UserType.connection_type,
      null: true, complexity: 5, resolver: Resolvers::Users::ParticipantsResolver,
      description: 'List of participants for the epic.'

    field :subscribed, GraphQL::Types::Boolean,
      method: :subscribed?, null: false, complexity: 5,
      description: 'Indicates the currently logged in user is subscribed to the epic.'

    field :issues, Types::EpicIssueType.connection_type,
      null: true, complexity: 5, resolver: Resolvers::EpicIssuesResolver,
      description: 'A list of issues associated with the epic.'

    field :descendant_counts, Types::EpicDescendantCountType,
      null: true, description: 'Number of open and closed descendant epics and issues.'

    field :descendant_weight_sum, Types::EpicDescendantWeightSumType,
      null: true,
      description: 'Total weight of open and closed issues in the epic and its descendants.'

    field :health_status, Types::EpicHealthStatusType,
      null: true, complexity: 10, description: 'Current health status of the epic.'

    field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
      null: true, authorize: :read_emoji,
      description: 'List of award emojis associated with the epic.'

    field :ancestors, Types::EpicType.connection_type,
      null: true, complexity: 5, resolver: ::Resolvers::EpicAncestorsResolver,
      description: 'Ancestors (parents) of the epic.'

    field :color, GraphQL::Types::String,
      null: true,
      description: 'Color of the epic. Returns `null` if `epic_color_highlight` feature flag is disabled.'

    field :text_color, GraphQL::Types::String,
      null: true,
      description: 'Text color generated for the epic. Returns `null` ' \
                   'if `epic_color_highlight` feature flag is disabled.'

    field :blocked, GraphQL::Types::Boolean,
      null: true, description: 'Indicates the epic is blocked.'

    field :blocking_count, GraphQL::Types::Int,
      null: true, complexity: 5,
      description: 'Count of epics that this epic is blocking.'

    field :blocked_by_count, GraphQL::Types::Int,
      null: true, description: 'Count of epics blocking this epic.'

    field :blocked_by_epics, ::Types::EpicType.connection_type,
      null: true, complexity: 5, description: 'Epics blocking this epic.'

    field :default_project_for_issue_creation, Types::ProjectType,
      null: true, resolver: ::Resolvers::Epics::DefaultProjectForIssueCreationResolver,
      description: 'Default Project for issue creation. Based on the project the user created the last issue in.'

    markdown_field :title_html, null: true
    markdown_field :description_html, null: true

    def has_children?
      Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate.new(context, object.id, COUNT) do |node, _aggregate_object|
        node.children.any?
      end
    end

    def has_issues?
      Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate.new(context, object.id, COUNT) do |node, _aggregate_object|
        node.has_issues?
      end
    end

    alias_method :has_children, :has_children?
    alias_method :has_issues, :has_issues?

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end

    def descendant_counts
      Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate.new(context, object.id, COUNT)
    end

    def descendant_weight_sum
      Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate.new(context, object.id, WEIGHT_SUM)
    end

    def health_status
      ::Epics::DescendantCountService.new(object, context[:current_user])
    end

    def blocked
      ::Gitlab::Graphql::Aggregations::Epics::LazyLinksAggregate.new(context, object.id) do |count|
        (count || 0) > 0
      end
    end

    def blocked_by_count
      ::Gitlab::Graphql::Aggregations::Epics::LazyLinksAggregate.new(context, object.id) do |count|
        count || 0
      end
    end

    def blocking_count
      ::Gitlab::Graphql::Aggregations::Epics::LazyLinksAggregate.new(context, object.id, link_type: :blocking) do |count|
        count || 0
      end
    end

    def blocked_by_epics
      object.blocked_by_epics_for(current_user)
    end

    def color
      object.color if Feature.enabled?(:epic_color_highlight, object.group)
    end

    def text_color
      object.text_color if Feature.enabled?(:epic_color_highlight, object.group)
    end
  end
end
