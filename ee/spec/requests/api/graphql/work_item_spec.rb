# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)' do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: project.group)) }
  # rubocop:disable Layout/LineLength
  let_it_be(:work_item) { create(:work_item, project: project, description: '- List item', weight: 1, iteration: iteration) }
  # rubocop:enable Layout/LineLength

  let(:current_user) { guest }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem') }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  context 'when the user can read the work item' do
    before do
      project.add_guest(guest)
    end

    context 'when querying widgets' do
      describe 'iteration widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetIteration {
                iteration {
                  id
                }
              }
            }
          GRAPHQL
        end

        context 'when iterations feature is licensed' do
          before do
            stub_licensed_features(iterations: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'ITERATION',
                  'iteration' => {
                    'id' => work_item.iteration.to_global_id.to_s
                  }
                )
              )
            )
          end
        end

        context 'when iteration feature is unlicensed' do
          before do
            stub_licensed_features(iterations: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without iteration' do
            expect(work_item_data).not_to include(
              'widgets' => include(
                hash_including('type' => 'ITERATION')
              )
            )
          end
        end
      end

      describe 'weight widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetWeight {
                weight
              }
            }
          GRAPHQL
        end

        context 'when issuable weights is licensed' do
          before do
            stub_licensed_features(issue_weights: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'WEIGHT',
                  'weight' => work_item.weight
                )
              )
            )
          end
        end

        context 'when issuable weights is unlicensed' do
          before do
            stub_licensed_features(issue_weights: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without weight' do
            expect(work_item_data).not_to include(
              'widgets' => include(
                hash_including(
                  'type' => 'WEIGHT',
                  'weight' => work_item.weight
                )
              )
            )
          end
        end
      end

      describe 'verification status widget' do
        let_it_be(:work_item) { create(:work_item, :requirement, project: project) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetVerificationStatus {
                verificationStatus
              }
            }
          GRAPHQL
        end

        context 'when requirements is licensed' do
          before do
            stub_licensed_features(requirements: true)

            post_graphql(query, current_user: current_user)
          end

          shared_examples 'response with verification status information' do
            it 'returns correct data' do
              expect(work_item_data).to include(
                'id' => work_item.to_gid.to_s,
                'widgets' => include(
                  hash_including(
                    'type' => 'VERIFICATION_STATUS',
                    'verificationStatus' => status
                  )
                )
              )
            end
          end

          context 'when latest test report status is satisfied' do
            let_it_be(:test_report) { create(:test_report, requirement_issue: work_item, state: :passed) }

            it_behaves_like 'response with verification status information' do
              let(:status) { 'satisfied' }
            end
          end

          context 'when latest test report status is failed' do
            let_it_be(:test_report) { create(:test_report, requirement_issue: work_item, state: :failed) }

            it_behaves_like 'response with verification status information' do
              let(:status) { 'failed' }
            end
          end

          context 'with no test report' do
            it_behaves_like 'response with verification status information' do
              let(:status) { 'unverified' }
            end
          end
        end

        context 'when requirements is unlicensed' do
          before do
            stub_licensed_features(requirements: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns no verification status information' do
            expect(work_item_data).not_to include(
              'widgets' => include(
                hash_including(
                  'type' => 'VERIFICATION_STATUS',
                  'verificationStatus' => 'unverified'
                )
              )
            )
          end
        end
      end

      describe 'labels widget' do
        let(:labels) { create_list(:label, 2, project: project) }
        let(:work_item) { create(:work_item, project: project, labels: labels) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetLabels {
                allowsScopedLabels
                labels {
                  nodes {
                    id
                    title
                  }
                }
              }
            }
          GRAPHQL
        end

        where(:has_scoped_labels_license) do
          [true, false]
        end

        with_them do
          it 'returns widget information' do
            stub_licensed_features(scoped_labels: has_scoped_labels_license)

            post_graphql(query, current_user: current_user)

            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'LABELS',
                  'allowsScopedLabels' => has_scoped_labels_license,
                  'labels' => {
                    'nodes' => match_array(
                      labels.map { |a| { 'id' => a.to_gid.to_s, 'title' => a.title } }
                    )
                  }
                )
              )
            )
          end
        end
      end
    end
  end
end
