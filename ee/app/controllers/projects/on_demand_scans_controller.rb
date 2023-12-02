# frozen_string_literal: true

module Projects
  class OnDemandScansController < Projects::ApplicationController
    include SecurityAndCompliancePermissions
    include API::Helpers::GraphqlHelpers

    before_action :authorize_read_on_demand_dast_scan!, only: :index
    before_action :authorize_create_on_demand_dast_scan!, only: [:new, :edit]
    before_action do
      push_frontend_feature_flag(:dast_ui_redesign, @project)
      push_frontend_feature_flag(:dast_api_scanner, @project)
    end

    feature_category :dynamic_application_security_testing

    def index
    end

    def new
    end

    def edit
      global_id = Gitlab::GlobalId.as_global_id(params[:id], model_name: 'Dast::Profile')

      query = %(
          {
            project(fullPath: "#{project.full_path}") {
              dastProfile(id: "#{global_id}") {
                id
                name
                description
                branch { name }
                dastSiteProfile { id }
                dastScannerProfile { id }
                dastProfileSchedule {
                  active
                  cadence {
                    duration
                    unit
                  }
                  startsAt
                  timezone
                }
              }
            }
          }
        )

      @dast_profile = run_graphql!(
        query: query,
        context: { current_user: current_user },
        transform: -> (result) { result.dig('data', 'project', 'dastProfile') }
      )

      return render_404 unless @dast_profile
    end
  end
end
