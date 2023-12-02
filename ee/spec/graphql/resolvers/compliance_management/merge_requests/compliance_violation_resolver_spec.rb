# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::ComplianceManagement::MergeRequests::ComplianceViolationResolver' do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged, title: 'abcd') }
  let_it_be(:merge_request2) { create(:merge_request, source_project: project2, target_project: project2, state: :merged, title: 'zyxw') }
  let_it_be(:merge_request_outside_group) { create(:merge_request, source_project: project_outside_group, target_project: project_outside_group, state: :merged) }
  let_it_be(:compliance_violation) { create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request) }
  let_it_be(:compliance_violation2) { create(:compliance_violation, :approved_by_merge_request_author, severity_level: :high, merge_request: merge_request2) }
  let_it_be(:compliance_violation_outside_group) { create(:compliance_violation, :approved_by_committer, merge_request: merge_request_outside_group) }
  let_it_be(:described_class) { Resolvers::ComplianceManagement::MergeRequests::ComplianceViolationResolver }

  before do
    merge_request.metrics.update!(merged_at: 3.days.ago)
    merge_request2.metrics.update!(merged_at: 1.day.ago)
  end

  describe '#resolve' do
    let(:args) { {} }

    subject(:resolve_compliance_violations) { resolve(described_class, obj: group, args: args, ctx: { current_user: current_user }) }

    context 'user is unauthorized' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'user is authorized' do
      before do
        group.add_owner(current_user)
      end

      context 'without any filters or sorting' do
        it 'finds all the compliance violations' do
          expect(subject).to contain_exactly(compliance_violation, compliance_violation2)
        end
      end

      context 'filtering the results' do
        context 'when given an array of project IDs' do
          let(:args) { { filters: { project_ids: [::Gitlab::GlobalId.as_global_id(project.id, model_name: 'Project')] } } }

          it 'finds the filtered compliance violations' do
            expect(subject).to contain_exactly(compliance_violation)
          end
        end

        context 'when given merged at dates' do
          where(:merged_params, :result) do
            { merged_before: 2.days.ago.to_date } | lazy { compliance_violation }
            { merged_after: 2.days.ago.to_date } | lazy { compliance_violation2 }
            { merged_before: Date.current, merged_after: 2.days.ago.to_date } | lazy { compliance_violation2 }
          end

          with_them do
            let(:args) { { filters: merged_params } }

            it 'finds the filtered compliance violations' do
              expect(subject).to contain_exactly(result)
            end
          end
        end
      end

      context 'sorting the results' do
        where(:direction, :pagination_type, :result) do
          'SEVERITY_LEVEL_ASC' | :keyset | lazy { [compliance_violation, compliance_violation2] }
          'SEVERITY_LEVEL_DESC' | :keyset | lazy { [compliance_violation2, compliance_violation] }
          'VIOLATION_REASON_ASC' | :keyset | lazy { [compliance_violation, compliance_violation2] }
          'VIOLATION_REASON_DESC' | :keyset | lazy { [compliance_violation2, compliance_violation] }
          'MERGE_REQUEST_TITLE_ASC' | :offset | lazy { [compliance_violation, compliance_violation2] }
          'MERGE_REQUEST_TITLE_DESC' | :offset | lazy { [compliance_violation2, compliance_violation] }
          'MERGED_AT_ASC' | :offset |  lazy { [compliance_violation, compliance_violation2] }
          'MERGED_AT_DESC' | :offset | lazy { [compliance_violation2, compliance_violation] }
          'UNKNOWN_SORT' | :keyset | lazy { [compliance_violation, compliance_violation2] }
        end

        with_them do
          let(:args) { { sort: direction } }

          it 'finds the filtered compliance violations' do
            expect(subject).to match_array(result)
          end

          if params[:pagination_type] == :keyset
            it "uses keyset pagination" do
              expect(subject).to be_a(::Gitlab::Graphql::Pagination::Keyset::Connection)
            end
          else
            it "uses offset pagination" do
              expect(subject).to be_a(::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
            end
          end
        end
      end
    end
  end
end
