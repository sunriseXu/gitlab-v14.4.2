# frozen_string_literal: true

module Vulnerabilities
  module SecurityFinding
    class CreateIssueService < ::BaseProjectService
      include VulnerabilitiesHelper

      attr_reader :error_message

      def execute
        raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_security_resource, @project)

        issue = nil
        @error_message = nil

        ApplicationRecord.transaction do
          vulnerability = create_vulnerability
          issue = create_issue(vulnerability)
          create_vulnerability_issue_link(vulnerability, issue)
        end

        return error_response if @error_message

        success_response(issue)
      end

      private

      def create_vulnerability
        vulnerability_response = Vulnerabilities::CreateFromSecurityFindingService.new(project: @project,
                                                                                       current_user: @current_user,
                                                                                       params: params,
                                                                                       state: 'confirmed').execute

        if vulnerability_response.error?
          @error_message = vulnerability_response[:message]
          raise ActiveRecord::Rollback
        end

        vulnerability_response.payload[:vulnerability]
      end

      def create_issue(vulnerability)
        vulnerability_data = vulnerability_data_with_category(vulnerability)

        issue_response = Issues::CreateFromVulnerabilityDataService.new(@project,
                                                                        @current_user,
                                                                        vulnerability_data).execute

        if issue_response[:status] == :error
          @error_message = issue_response[:message]
          raise ActiveRecord::Rollback
        end

        issue_response[:issue]
      end

      def create_vulnerability_issue_link(vulnerability, issue)
        issue_link_response = VulnerabilityIssueLinks::CreateService
          .new(@current_user, vulnerability, issue, link_type: Vulnerabilities::IssueLink.link_types[:created])
          .execute

        if issue_link_response[:status] == :error
          @error_message = issue_link_response[:message]
          raise ActiveRecord::Rollback
        end
      end

      def error_response
        ServiceResponse.error(message: @error_message)
      end

      def success_response(issue)
        ServiceResponse.success(payload: { issue: issue })
      end
    end
  end
end
