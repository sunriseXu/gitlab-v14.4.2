# frozen_string_literal: true

module API
  class Epics < ::API::Base
    include PaginationParams

    feature_category :portfolio_management

    before do
      authenticate_non_get!
      authorize_epics_feature!
    end

    helpers ::API::Helpers::EpicsHelpers

    helpers do
      params :negatable_epic_filter_params do
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'

        optional :author_id, type: Integer, desc: 'Return epics which are not authored by the user with the given ID'
        optional :author_username, type: String, desc: 'Return epics which are not authored by the given username'
        mutually_exclusive :author_id, :author_username
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get epics for the group' do
        success EE::API::Entities::Epic
      end
      params do
        optional :order_by, type: String, values: %w[created_at updated_at title], default: 'created_at',
                            desc: 'Return epics ordered by `created_at`, `updated_at` or `title` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return epics sorted in `asc` or `desc` order.'
        optional :search, type: String, desc: 'Search epics for text present in the title or description'
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all epics'

        optional :author_id, type: Integer, desc: 'Return epics which are authored by the user with the given ID'
        optional :author_username, type: String, desc: 'Return epics which are authored by the given username'
        mutually_exclusive :author_id, :author_username

        optional :labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :created_after, type: DateTime, desc: 'Return epics created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return epics created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return epics updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return epics updated before the specified time'
        optional :include_ancestor_groups, type: Boolean, default: false, desc: 'Include epics from ancestor groups'
        optional :include_descendant_groups, type: Boolean, default: true, desc: 'Include epics from descendant groups'
        optional :my_reaction_emoji, type: String, desc: 'Return epics reacted by the authenticated user by the given emoji'
        optional :confidential, type: Boolean, desc: 'Return epics with given confidentiality'
        use :pagination

        optional :not, type: Hash do
          use :negatable_epic_filter_params
        end
      end
      [':id/epics', ':id/-/epics'].each do |path|
        get path, urgency: :low do
          validate_anonymous_search_access! if declared_params[:search].present?
          epics = paginate(find_epics(finder_params: { group_id: user_group.id })).with_api_entity_associations

          # issuable_metadata has to be set because `Entities::Epic` doesn't inherit from `Entities::IssuableEntity`
          extra_options = { issuable_metadata: Gitlab::IssuableMetadata.new(current_user, epics).data, with_labels_details: declared_params[:with_labels_details] }
          present epics, epic_options.merge(extra_options)
        end
      end

      desc 'Get details of an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      [':id/epics/:epic_iid', ':id/-/epics/:epic_iid'].each do |path|
        get path do
          authorize_can_read!

          present epic, epic_options.merge(include_subscribed: true)
        end
      end

      desc 'Create a new epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :title, type: String, desc: 'The title of an epic'
        optional :description, type: String, desc: 'The description of an epic'
        optional :color, type: ::Gitlab::Color, desc: 'The color of an epic', coerce_with: ->(value) { ::Gitlab::Color.of(value) unless value.nil? }
        optional :confidential, type: Boolean, desc: 'Indicates if the epic is confidential'
        optional :created_at, type: DateTime, desc: 'Date time when the epic was created. Available only for admins and project owners.'
        optional :start_date, as: :start_date_fixed, type: String, desc: 'The start date of an epic'
        optional :start_date_is_fixed, type: Boolean, desc: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones'
        optional :end_date, as: :due_date_fixed, type: String, desc: 'The due date of an epic'
        optional :due_date_is_fixed, type: Boolean, desc: 'Indicates due date should be sourced from due_date_fixed field not the issue milestones'
        optional :labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :parent_id, type: Integer, desc: 'The id of a parent epic'
      end
      post ':id/(-/)epics' do
        authorize_can_create!

        # Setting created_at is allowed only for admins and owners
        params.delete(:created_at) unless current_user.can?(:set_epic_created_at, user_group)
        params.delete(:color) unless Feature.enabled?(:epic_color_highlight)

        epic = ::Epics::CreateService.new(group: user_group, current_user: current_user, params: declared_params(include_missing: false)).execute
        if epic.valid?
          present epic, epic_options
        else
          render_validation_error!(epic)
        end
      end

      desc 'Update an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
        optional :title, type: String, desc: 'The title of an epic'
        optional :color, type: ::Gitlab::Color, desc: 'The color of an epic', coerce_with: ->(value) { ::Gitlab::Color.of(value) unless value.nil? }
        optional :description, type: String, desc: 'The description of an epic'
        optional :confidential, type: Boolean, desc: 'Indicates if the epic is confidential'
        optional :updated_at, type: DateTime, desc: 'Date time when the epic was updated. Available only for admins and project owners.'
        optional :start_date, as: :start_date_fixed, type: String, desc: 'The start date of an epic'
        optional :start_date_is_fixed, type: Boolean, desc: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones'
        optional :end_date, as: :due_date_fixed, type: String, desc: 'The due date of an epic'
        optional :due_date_is_fixed, type: Boolean, desc: 'Indicates due date should be sourced from due_date_fixed field not the issue milestones'
        optional :labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :add_labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :remove_labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :state_event, type: String, values: %w[reopen close], desc: 'State event for an epic'
        optional :parent_id, type: Integer, desc: 'The id of a parent epic'
        at_least_one_of :add_labels, :color, :confidential, :description, :due_date_fixed, :due_date_is_fixed, :labels, :parent_id, :remove_labels, :start_date_fixed, :start_date_is_fixed, :state_event, :title
      end
      put ':id/(-/)epics/:epic_iid' do
        authorize_can_admin_epic!

        # Setting updated_at is allowed only for admins and owners
        params.delete(:updated_at) unless current_user.can?(:set_epic_updated_at, user_group)
        params.delete(:color) unless Feature.enabled?(:epic_color_highlight)

        update_params = declared_params(include_missing: false)
        update_params.delete(:epic_iid)

        result = ::Epics::UpdateService.new(group: user_group, current_user: current_user, params: update_params).execute(epic)

        if result.valid?
          present result, epic_options
        else
          render_validation_error!(result)
        end
      end

      desc 'Destroy an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      delete ':id/(-/)epics/:epic_iid' do
        authorize_can_destroy!

        Issuable::DestroyService.new(project: nil, current_user: current_user).execute(epic)
      end
    end
  end
end
