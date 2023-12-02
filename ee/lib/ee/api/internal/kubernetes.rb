# frozen_string_literal: true
module EE
  module API
    module Internal
      module Kubernetes
        extend ActiveSupport::Concern
        prepended do
          namespace 'internal' do
            namespace 'kubernetes' do
              before { check_agent_token }

              namespace 'modules/starboard_vulnerability', urgency: :low do
                desc 'PUT starboard vulnerability' do
                  detail 'Idempotently creates a security vulnerability from starboard'
                end
                params do
                  requires :vulnerability, type: Hash, desc: 'Vulnerability details matching the `vulnerability` object on the security report schema' do
                    requires :name, type: String
                    requires :severity, type: String, coerce_with: ->(s) { s.downcase }
                    optional :confidence, type: String, coerce_with: ->(c) { c.downcase }

                    requires :location, type: Hash do
                      requires :image, type: String

                      requires :dependency, type: Hash do
                        requires :package, type: Hash do
                          requires :name, type: String
                        end

                        optional :version, type: String
                      end

                      requires :kubernetes_resource, type: Hash do
                        requires :namespace, type: String
                        requires :name, type: String
                        requires :kind, type: String
                        requires :container_name, type: String
                        requires :agent_id, type: String
                      end

                      optional :operating_system, type: String
                    end

                    requires :identifiers, type: Array do
                      requires :type, type: String
                      requires :name, type: String
                      optional :value, type: String
                      optional :url, type: String
                    end

                    optional :message, type: String
                    optional :description, type: String
                    optional :solution, type: String
                    optional :links, type: Array
                  end

                  requires :scanner, type: Hash, desc: 'Scanner details matching the `.scan.scanner` field on the security report schema' do
                    requires :id, type: String
                    requires :name, type: String
                    requires :vendor, type: Hash do
                      requires :name, type: String
                    end
                  end
                end

                route_setting :authentication, cluster_agent_token_allowed: true
                put '/' do
                  not_found! if agent.project.nil?

                  result = ::Vulnerabilities::StarboardVulnerabilityCreateService.new(
                    agent,
                    params: params
                  ).execute

                  if result.success?
                    status result.http_status
                    { uuid: result.payload[:vulnerability].finding_uuid }
                  else
                    render_api_error!(result.message, result.http_status)
                  end
                end

                desc 'POST scan_result' do
                  detail 'Resolves all active Cluster Image Scanning vulnerabilities with finding UUIDs not present in the payload'
                end
                params do
                  requires :uuids, type: Array[String], desc: 'Finding UUIDs collected from a scan'
                end

                route_setting :authentication, cluster_agent_token_allowed: true
                post "/scan_result", urgency: :low do
                  not_found! if agent.project.nil?

                  service = ::Vulnerabilities::StarboardVulnerabilityResolveService.new(agent, params[:uuids])
                  result = service.execute

                  status result.http_status
                end

                desc 'GET starboard policies_configuration' do
                  detail 'Retrieves policies_configuration for the project'
                end

                route_setting :authentication, cluster_agent_token_allowed: true
                get '/policies_configuration' do
                  not_found! if agent.project.nil?
                  not_found! unless agent.project.licensed_feature_available?(:security_orchestration_policies)

                  policies = ::Security::SecurityOrchestrationPolicies::OperationalVulnerabilitiesConfigurationService
                    .new(agent)
                    .execute

                  present :configurations, policies, with: EE::API::Entities::SecurityPolicyConfiguration
                end
              end
            end
          end
        end
      end
    end
  end
end
