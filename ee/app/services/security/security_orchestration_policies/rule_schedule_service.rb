# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class RuleScheduleService < BaseContainerService
      def execute(schedule)
        branches = schedule.applicable_branches(container)
        actions_for(schedule).each { |action| process_action(action, schedule, branches) }
      end

      private

      def actions_for(schedule)
        policy = schedule.policy
        return [] if policy.blank?

        policy[:actions]
      end

      def process_action(action, schedule, branches)
        case action[:scan].to_s
        when 'secret_detection' then schedule_scan(action, branches)
        when 'container_scanning' then schedule_scan(action, branches)
        when 'dast' then schedule_dast_on_demand_scan(action, branches)
        when 'sast' then schedule_scan(action, branches)
        end
      end

      def schedule_scan(action, branches)
        branches.each do |branch|
          ::Security::SecurityOrchestrationPolicies::CreatePipelineService
            .new(project: container, current_user: current_user, params: { action: action, branch: branch })
            .execute
        end
      end

      def schedule_dast_on_demand_scan(action, branches)
        dast_site_profile = find_dast_site_profile(container, action[:site_profile])
        dast_scanner_profile = find_dast_scanner_profile(container, action[:scanner_profile])

        branches.each do |branch|
          ::AppSec::Dast::Scans::CreateService.new(
            container: container,
            current_user: current_user,
            params: {
              branch: branch,
              dast_site_profile: dast_site_profile,
              dast_scanner_profile: dast_scanner_profile
            }
          ).execute
        end
      end

      def find_dast_site_profile(project, dast_site_profile)
        DastSiteProfilesFinder.new(project_id: project.id, name: dast_site_profile).execute.first
      end

      def find_dast_scanner_profile(project, dast_scanner_profile)
        return unless dast_scanner_profile

        DastScannerProfilesFinder.new(project_ids: [project.id], name: dast_scanner_profile).execute.first
      end
    end
  end
end
