# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Environments query' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be_with_refind(:production) { create(:environment, :production, project: project) }
  let_it_be_with_refind(:staging) { create(:environment, :staging, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }

  subject { post_graphql(query, current_user: user) }

  let(:user) { developer }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          environment(name: "#{production.name}") {
            slug
            createdAt
            updatedAt
            autoStopAt
            autoDeleteAt
            tier
            environmentType
          }
        }
      }
    )
  end

  it 'returns the specified fields of the environment', :aggregate_failures do
    production.update!(auto_stop_at: 1.day.ago, auto_delete_at: 2.days.ago, environment_type: 'review')

    subject

    environment_data = graphql_data.dig('project', 'environment')
    expect(environment_data['slug']).to eq(production.slug)
    expect(environment_data['createdAt']).to eq(production.created_at.iso8601)
    expect(environment_data['updatedAt']).to eq(production.updated_at.iso8601)
    expect(environment_data['autoStopAt']).to eq(production.auto_stop_at.iso8601)
    expect(environment_data['autoDeleteAt']).to eq(production.auto_delete_at.iso8601)
    expect(environment_data['tier']).to eq(production.tier.upcase)
    expect(environment_data['environmentType']).to eq(production.environment_type)
  end

  describe 'last deployments of environments' do
    ::Deployment.statuses.each do |status, _|
      let_it_be(:"production_#{status}_deployment") do
        create(:deployment, status.to_sym, environment: production, project: project)
      end

      let_it_be(:"staging_#{status}_deployment") do
        create(:deployment, status.to_sym, environment: staging, project: project)
      end
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environments {
              nodes {
                name
                lastSuccessDeployment: lastDeployment(status: SUCCESS) {
                  iid
                }
                lastRunningDeployment: lastDeployment(status: RUNNING) {
                  iid
                }
                lastBlockedDeployment: lastDeployment(status: BLOCKED) {
                  iid
                }
              }
            }
          }
        }
      )
    end

    it 'returns all last deployments of the environment' do
      subject

      environments_data = graphql_data_at(:project, :environments, :nodes)

      environments_data.each do |environment_data|
        name = environment_data['name']
        success_deployment = public_send(:"#{name}_success_deployment")
        running_deployment = public_send(:"#{name}_running_deployment")
        blocked_deployment = public_send(:"#{name}_blocked_deployment")

        expect(environment_data['lastSuccessDeployment']['iid']).to eq(success_deployment.iid.to_s)
        expect(environment_data['lastRunningDeployment']['iid']).to eq(running_deployment.iid.to_s)
        expect(environment_data['lastBlockedDeployment']['iid']).to eq(blocked_deployment.iid.to_s)
      end
    end

    it 'executes the same number of queries in single environment and multiple environments' do
      single_environment_query =
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{production.name}") {
                name
                lastSuccessDeployment: lastDeployment(status: SUCCESS) {
                  iid
                }
                lastRunningDeployment: lastDeployment(status: RUNNING) {
                  iid
                }
                lastBlockedDeployment: lastDeployment(status: BLOCKED) {
                  iid
                }
              }
            }
          }
        )

      baseline = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(single_environment_query, context: { current_user: user })
      end

      multi = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(query, context: { current_user: user })
      end

      expect(multi).not_to exceed_query_limit(baseline)
    end
  end
end
