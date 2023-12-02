# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Group'] do
  include GraphqlHelpers

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Group) }

  specify { expect(described_class.graphql_name).to eq('Group') }

  specify { expect(described_class).to require_graphql_authorizations(:read_group) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics
      web_url avatar_url share_with_group_lock project_creation_level
      subgroup_creation_level require_two_factor_authentication
      two_factor_grace_period auto_devops_enabled emails_disabled
      mentions_disabled parent boards milestones group_members
      merge_requests container_repositories container_repositories_count
      packages dependency_proxy_setting dependency_proxy_manifests
      dependency_proxy_blobs dependency_proxy_image_count
      dependency_proxy_blob_count dependency_proxy_total_size
      dependency_proxy_image_prefix dependency_proxy_image_ttl_policy
      shared_runners_setting timelogs organization_state_counts organizations
      contact_state_counts contacts work_item_types
      recent_issue_boards ci_variables
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'boards field' do
    subject { described_class.fields['boards'] }

    it 'returns boards' do
      is_expected.to have_graphql_type(Types::BoardType.connection_type)
    end
  end

  describe 'members field' do
    subject { described_class.fields['groupMembers'] }

    it { is_expected.to have_graphql_type(Types::GroupMemberType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::GroupMembersResolver) }
  end

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'finds timelogs between start time and end time' do
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_non_null_graphql_type(Types::TimelogType.connection_type)
    end
  end

  describe 'contact_state_counts field' do
    subject { described_class.fields['contactStateCounts'] }

    it { is_expected.to have_graphql_type(Types::CustomerRelations::ContactStateCountsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Crm::ContactStateCountsResolver) }
  end

  describe 'organization_state_counts field' do
    subject { described_class.fields['organizationStateCounts'] }

    it { is_expected.to have_graphql_type(Types::CustomerRelations::OrganizationStateCountsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Crm::OrganizationStateCountsResolver) }
  end

  it_behaves_like 'a GraphQL type with labels' do
    let(:labels_resolver_arguments) { [:search_term, :includeAncestorGroups, :includeDescendantGroups, :onlyGroupLabels] }
  end

  describe 'milestones' do
    let(:user) { create(:user) }
    let(:subgroup) { create(:group, parent: create(:group)) }
    let(:query) do
      %(
        query {
          group(fullPath: "#{subgroup.full_path}") {
            milestones {
              nodes {
                id
                title
                projectMilestone
                groupMilestone
                subgroupMilestone
              }
            }
          }
        }
      )
    end

    def clean_state_query
      run_with_clean_state(query, context: { current_user: user })
    end

    it 'avoids N+1 queries' do
      subgroup.add_reporter(user)

      create(:milestone, group: subgroup)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { clean_state_query }

      create_list(:milestone, 2, group: subgroup)

      expect { clean_state_query }.not_to exceed_all_query_limit(control)
    end
  end
end
