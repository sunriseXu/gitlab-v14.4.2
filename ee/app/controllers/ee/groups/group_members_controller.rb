# frozen_string_literal: true

module EE
  module Groups
    module GroupMembersController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :admin_not_required_endpoints
        def admin_not_required_endpoints
          super.concat(%i[update override])
        end
      end

      prepended do
        # This before_action needs to be redefined so we can use the new values
        # from `admin_not_required_endpoints`.
        before_action :authorize_admin_group_member!, except: admin_not_required_endpoints
        before_action :authorize_update_group_member!, only: [:update, :override]

        before_action do
          push_frontend_feature_flag(:overage_members_modal, @group) if ::Gitlab::CurrentSettings.should_check_namespace_plan?
          push_frontend_feature_flag(:limit_unique_project_downloads_per_namespace_user, @group)
          push_licensed_feature(:unique_project_download_limit, @group)
        end
      end

      override :index
      def index
        super

        @banned = banned_members # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # rubocop: disable CodeReuse/ActiveRecord
      def override
        member = membershipable_members.find(params[:id])

        result = ::Members::UpdateService.new(current_user, override_params).execute(member, permission: :override)

        respond_to do |format|
          format.js do
            if result[:status] == :success
              head :ok
            else
              render json: result[:message], status: :unprocessable_entity
            end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def export_csv
        return render_404 unless current_user.can?(:export_group_memberships, group)

        ::Groups::ExportMembershipsWorker.perform_async(group.id, current_user.id)

        redirect_to group_group_members_path(group), notice: _('CSV is being generated and will be emailed to you upon completion.')
      end

      protected

      override :invited_members
      def invited_members
        super.or(group_members.awaiting.with_invited_user_state)
      end

      override :non_invited_members
      def non_invited_members
        super.non_awaiting
      end

      def banned_members
        return unless group.unique_project_download_limit_enabled?
        return unless can?(current_user, :admin_group_member, group)

        present_members(group_members.banned)
      end

      def authorize_update_group_member!
        unless can?(current_user, :admin_group_member, group) || can?(current_user, :override_group_member, group)
          render_403
        end
      end

      def override_params
        params.require(:group_member).permit(:override)
      end

      override :membershipable_members
      def membershipable_members
        return super unless group.licensed_feature_available?(:minimal_access_role)

        group.all_group_members
      end

      override :filter_params
      def filter_params
        super.merge(params.permit(:enterprise))
      end
    end
  end
end
