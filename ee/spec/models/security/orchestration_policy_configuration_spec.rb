# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyConfiguration do
  let_it_be(:security_policy_management_project) { create(:project, :repository) }

  let(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project)
  end

  let(:default_branch) { security_policy_management_project.default_branch }
  let(:repository) { instance_double(Repository, root_ref: 'master', empty?: false) }
  let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy, name: 'Run DAST in every pipeline')], scan_result_policy: [build(:scan_result_policy, name: 'Containe security critical severities')]) }

  before do
    allow(security_policy_management_project).to receive(:repository).and_return(repository)
    allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:security_orchestration_policy_configuration) }
    it { is_expected.to belong_to(:namespace).inverse_of(:security_orchestration_policy_configuration) }
    it { is_expected.to belong_to(:security_policy_management_project).class_name('Project') }
    it { is_expected.to have_many(:rule_schedules).class_name('Security::OrchestrationPolicyRuleSchedule').inverse_of(:security_orchestration_policy_configuration) }
  end

  describe 'validations' do
    subject { create(:security_orchestration_policy_configuration) }

    context 'when created for project' do
      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.to validate_uniqueness_of(:project) }
    end

    context 'when created for namespace' do
      subject { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.not_to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:namespace) }
      it { is_expected.to validate_uniqueness_of(:namespace) }
    end

    it { is_expected.to validate_presence_of(:security_policy_management_project) }
  end

  describe '.for_project' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration) }

    subject { described_class.for_project([security_orchestration_policy_configuration_2.project, security_orchestration_policy_configuration_3.project]) }

    it 'returns configuration for given projects' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.for_namespace' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, :namespace) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, :namespace) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, :namespace) }

    subject { described_class.for_namespace([security_orchestration_policy_configuration_2.namespace, security_orchestration_policy_configuration_3.namespace]) }

    it 'returns configuration for given namespaces' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.for_management_project' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration) }

    subject { described_class.for_management_project(security_policy_management_project) }

    it 'returns configuration for given the policy management project' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_1, security_orchestration_policy_configuration_2)
    end
  end

  describe '.with_outdated_configuration' do
    let!(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, configured_at: nil) }
    let!(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now - 1.hour) }
    let!(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now + 1.hour) }

    subject { described_class.with_outdated_configuration }

    it 'returns configuration with outdated configurations' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_1, security_orchestration_policy_configuration_2)
    end
  end

  describe '.policy_management_project?' do
    before do
      create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project)
    end

    it 'returns true when security_policy_management_project with id exists' do
      expect(described_class.policy_management_project?(security_policy_management_project.id)).to be_truthy
    end

    it 'returns false when security_policy_management_project with id does not exist' do
      expect(described_class.policy_management_project?(non_existing_record_id)).to be_falsey
    end
  end

  describe '.valid_scan_type?' do
    it 'returns true when scan type is valid' do
      expect(Security::ScanExecutionPolicy.valid_scan_type?('secret_detection')).to be_truthy
    end

    it 'returns false when scan type is invalid' do
      expect(Security::ScanExecutionPolicy.valid_scan_type?('invalid')).to be_falsey
    end
  end

  describe '#policy_configuration_exists?' do
    subject { security_orchestration_policy_configuration.policy_configuration_exists? }

    context 'when file is missing' do
      let(:policy_yaml) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when policy is present' do
      it { is_expected.to eq(true) }
    end
  end

  describe '#policy_hash' do
    subject { security_orchestration_policy_configuration.policy_hash }

    context 'when policy is present' do
      it { expect(subject.dig(:scan_execution_policy, 0, :name)).to eq('Run DAST in every pipeline') }
    end

    context 'when policy has invalid YAML format' do
      let(:policy_yaml) do
        'cadence: * 1 2 3'
      end

      it { expect(subject).to be_nil }
    end

    context 'when policy is nil' do
      let(:policy_yaml) { nil }

      it { expect(subject).to be_nil }
    end
  end

  describe '#policy_by_type' do
    subject { security_orchestration_policy_configuration.policy_by_type(:scan_execution_policy) }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    context 'when policy is present' do
      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy, name: 'Run DAST in every pipeline' )]) }

      it 'retrieves policy by type' do
        expect(subject.first[:name]).to eq('Run DAST in every pipeline')
      end
    end

    context 'when policy is nil' do
      let(:policy_yaml) { nil }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end
  end

  describe '#policy_configuration_valid?' do
    subject { security_orchestration_policy_configuration.policy_configuration_valid? }

    context 'when file is invalid' do
      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy:
        [build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: 'production' }])])
      end

      it { is_expected.to eq(false) }
    end

    context 'when file has invalid name' do
      let(:invalid_name) { 'a' * 256 }
      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy:
        [build(:scan_execution_policy, name: invalid_name)])
      end

      it { is_expected.to be false }
    end

    context 'when file is valid' do
      it { is_expected.to eq(true) }
    end

    context 'when policy is passed as argument' do
      let_it_be(:policy_yaml) { nil }
      let_it_be(:policy) { { scan_execution_policy: [build(:scan_execution_policy)] } }

      context 'when scan type is secret_detection' do
        it 'returns false if extra fields are present' do
          invalid_policy = policy.deep_dup
          invalid_policy[:scan_execution_policy][0][:actions][0][:scan] = 'secret_detection'

          expect(security_orchestration_policy_configuration.policy_configuration_valid?(invalid_policy)).to be_falsey
        end

        it 'returns true if extra fields are not present' do
          valid_policy = policy.deep_dup
          valid_policy[:scan_execution_policy][0][:actions][0] = { scan: 'secret_detection' }

          expect(security_orchestration_policy_configuration.policy_configuration_valid?(valid_policy)).to be_truthy
        end
      end

      context 'for schedule policy rule' do
        using RSpec::Parameterized::TableSyntax

        let_it_be(:schedule_policy) { { scan_execution_policy: [build(:scan_execution_policy, :with_schedule)] } }

        subject { security_orchestration_policy_configuration.policy_configuration_valid?(schedule_policy) }

        where(:cadence, :is_valid) do
          "@weekly"           | true
          "@yearly"           | true
          "@annually"         | true
          "@monthly"          | true
          "@weekly"           | true
          "@daily"            | true
          "@midnight"         | true
          "@noon"             | true
          "@hourly"           | true
          "* * * * *"         | true
          "0 0 2 3 *"         | true
          "* * L * *"         | true
          "* * -6 * *"        | true
          "* * -3 * *"        | true
          "* * 12 * *"        | true
          "0 9 -4 * *"        | true
          "0 0 -8 * *"        | true
          "7 10 * * *"        | true
          "00 07 * * *"       | true
          "* * * * tue"       | true
          "* * * * TUE"       | true
          "12 10 0 * *"       | true
          "52 20 * * 2"       | true
          "* * last * *"      | true
          "0 2 last * *"      | true
          "52 9 2-5 * 2"      | true
          "0 0 27 3 1,5"      | true
          "0 0 11 * 3-6"      | true
          "0 0 -7-L * *"      | true
          "0 0 -1,-2 * *"     | true
          "10/30 * * * *"     | true
          "21 37 4,12 * 3"    | true
          "02 07 21 jan *"    | true
          "02 07 21 JAN *"    | true
          "0 1 L * wed-fri"   | true
          "0 1 L * wed-FRI"   | true
          "0 1 L * WED-fri"   | true
          "0 1 L * WED-FRI"   | true
          "0 0 21 4 sat,sun"  | true
          "0 0 21 4 SAT,SUN"  | true
          "10-30/30 * * * *"  | true

          ""                  | false
          "1"                 | false
          "2 3 4"             | false
          "invalid"           | false
          "@WEEKLY"           | false
          "@YEARLY"           | false
          "@ANNUALLY"         | false
          "@MONTHLY"          | false
          "@WEEKLY"           | false
          "@DAILY"            | false
          "@MIDNIGHT"         | false
          "@NOON"             | false
          "@HOURLY"           | false
        end

        with_them do
          before do
            schedule_policy[:scan_execution_policy][0][:rules][0][:cadence] = cadence
          end

          it { is_expected.to eq(is_valid) }
        end
      end
    end

    context 'with scan result policies' do
      let(:policy_name) { 'Contains security critical severities' }
      let(:scan_result_policy) { build(:scan_result_policy, name: policy_name) }
      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [scan_result_policy]) }

      it { is_expected.to eq(true) }

      context 'with various approvers' do
        using RSpec::Parameterized::TableSyntax

        where(:user_approvers, :user_approvers_ids, :group_approvers, :group_approvers_ids, :is_valid) do
          []           | nil  | nil            | nil | false
          ['username'] | nil  | nil            | nil | true
          nil          | []   | nil            | nil | false
          nil          | [1]  | nil            | nil | true
          nil          | nil  | []             | nil | false
          nil          | nil  | ['group_path'] | nil | true
          nil          | nil  | nil            | []  | false
          nil          | nil  | nil            | [2] | true
        end

        with_them do
          let(:action) { { type: 'require_approval', approvals_required: 1, user_approvers: user_approvers, user_approvers_ids: user_approvers_ids, group_approvers: group_approvers, group_approvers_ids: group_approvers_ids }.compact }
          let(:scan_result_policy) { build(:scan_result_policy, name: 'Contains security critical severities', actions: [action]) }

          it { is_expected.to eq(is_valid) }
        end
      end

      context 'with various policy names' do
        using RSpec::Parameterized::TableSyntax

        where(:policy_name, :expected_to_be_valid) do
          ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT                 | false
          ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE                       | false
          "New #{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}"        | true
          "#{ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE} through policies" | true
        end

        with_them do
          it { is_expected.to eq(expected_to_be_valid) }
        end
      end
    end
  end

  describe '#policy_configuration_validation_errors' do
    subject { security_orchestration_policy_configuration.policy_configuration_validation_errors }

    context 'when file is invalid' do
      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy:
        [build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: 'production' }])])
      end

      it { is_expected.to eq(["property '/scan_execution_policy/0/rules/0/branches' is not of type: array"]) }
    end

    context 'when file is valid' do
      it { is_expected.to eq([]) }
    end

    context 'when policy is passed as argument' do
      let_it_be(:policy_yaml) { nil }
      let_it_be(:policy) { { scan_execution_policy: [build(:scan_execution_policy, :with_schedule)] } }

      context 'when scan type is secret_detection' do
        it 'returns false if extra fields are present' do
          invalid_policy = policy.deep_dup
          invalid_policy[:scan_execution_policy][0][:actions][0][:scan] = 'secret_detection'
          invalid_policy[:scan_execution_policy][0][:rules][0][:cadence] = 'invalid * * * *'

          expect(security_orchestration_policy_configuration.policy_configuration_validation_errors(invalid_policy)).to contain_exactly(
            "property '/scan_execution_policy/0/actions/0' is invalid: error_type=maxProperties",
            "property '/scan_execution_policy/0/rules/0/cadence' does not match pattern: (@(yearly|annually|monthly|weekly|daily|midnight|noon|hourly))|(?i)(((\\*|(\\-?\\d+\\,?)+)(\\/\\d+)?|last|L|(sun|mon|tue|wed|thu|fri|sat|\\-|\\,)+|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|\\-|\\,)+)\\s?){5,6}"
          )
        end

        it 'returns true if extra fields are not present' do
          valid_policy = policy.deep_dup
          valid_policy[:scan_execution_policy][0][:actions][0] = { scan: 'secret_detection' }

          expect(security_orchestration_policy_configuration.policy_configuration_validation_errors(valid_policy)).to eq([])
        end
      end
    end
  end

  describe '#active_scan_execution_policies' do
    let(:enforce_dast_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy)]) }
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    let(:expected_active_policies) do
      [
        build(:scan_execution_policy, name: 'Run DAST in every pipeline', rules: [{ type: 'pipeline', branches: %w[production] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v1', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v3', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v4', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v5', rules: [{ type: 'pipeline', branches: %w[master] }])
      ]
    end

    subject(:active_scan_execution_policies) { security_orchestration_policy_configuration.active_scan_execution_policies }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with( default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only enabled policies' do
      expect(active_scan_execution_policies).to eq(expected_active_policies)
    end
  end

  describe '#on_demand_scan_actions' do
    let(:policy1) { build(:scan_execution_policy) }
    let(:policy2) { build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: ['release/*'] }], actions: [{ scan: 'dast', site_profile: 'Site Profile 2', scanner_profile: 'Scanner Profile 2' }]) }
    let(:policy3) { build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: ['*'] }], actions: [{ scan: 'dast', site_profile: 'Site Profile 3', scanner_profile: 'Scanner Profile 3' }]) }
    let(:policy4) { build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: ['release/*'] }], actions: [{ scan: 'sast' }]) }
    let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy1, policy2, policy3, policy4]) }

    let(:expected_actions) do
      [
        { scan: 'dast', scanner_profile: 'Scanner Profile 2', site_profile: 'Site Profile 2' },
        { scan: 'dast', scanner_profile: 'Scanner Profile 3', site_profile: 'Site Profile 3' }
      ]
    end

    subject(:on_demand_scan_actions) do
      security_orchestration_policy_configuration.on_demand_scan_actions(ref)
    end

    context 'when ref is branch' do
      let(:ref) { 'refs/heads/release/123' }

      it 'returns only actions for on-demand scans applicable for branch' do
        expect(on_demand_scan_actions).to eq(expected_actions)
      end
    end

    context 'when ref is a tag' do
      let(:ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to be_empty }
    end
  end

  describe '#pipeline_scan_actions' do
    let(:policy1) { build(:scan_execution_policy) }
    let(:policy2) { build(:scan_execution_policy, actions: [{ scan: 'dast', site_profile: 'Site Profile 2', scanner_profile: 'Scanner Profile 2' }, { scan: 'secret_detection' }]) }
    let(:policy3) { build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: ['*'] }], actions: [{ scan: 'secret_detection' }]) }
    let(:policy4) { build(:scan_execution_policy, :with_schedule, actions: [{ scan: 'secret_detection' }]) }
    let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy1, policy2, policy3, policy4]) }

    let(:expected_actions) do
      [{ scan: 'secret_detection' }, { scan: 'secret_detection' }]
    end

    subject(:pipeline_scan_actions) do
      security_orchestration_policy_configuration.pipeline_scan_actions('refs/heads/master')
    end

    it 'returns only actions for pipeline scans applicable for branch' do
      expect(pipeline_scan_actions).to eq(expected_actions)
    end
  end

  describe '#active_policy_names_with_dast_site_profile' do
    let(:policy_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy: [
              build(:scan_execution_policy,
                    name: 'Run DAST in every pipeline',
                    actions: [
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile 2' }
                    ])
            ])
    end

    it 'returns list of policy names where site profile is referenced' do
      expect( security_orchestration_policy_configuration.active_policy_names_with_dast_site_profile('Site Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#active_policy_names_with_dast_scanner_profile' do
    let(:enforce_dast_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy: [
              build(:scan_execution_policy,
                    name: 'Run DAST in every pipeline',
                    actions: [
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
                      { scan: 'dast', site_profile: 'Site Profile 2', scanner_profile: 'Scanner Profile' }
                    ])
            ])
    end

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(enforce_dast_yaml)
    end

    it 'returns list of policy names where site profile is referenced' do
      expect(security_orchestration_policy_configuration.active_policy_names_with_dast_scanner_profile('Scanner Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#policy_last_updated_by' do
    let(:commit) { create(:commit, author: security_policy_management_project.first_owner) }

    subject(:policy_last_updated_by) { security_orchestration_policy_configuration.policy_last_updated_by }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it { is_expected.to eq(security_policy_management_project.first_owner) }
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#policy_last_updated_at' do
    let(:last_commit_updated_at) { Time.zone.now }
    let(:commit) { create(:commit) }

    subject(:policy_last_updated_at) { security_orchestration_policy_configuration.policy_last_updated_at }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it "returns commit's updated date" do
        commit.committed_date = last_commit_updated_at

        is_expected.to eq(policy_last_updated_at)
      end
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#delete_all_schedules' do
    let(:rule_schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    subject(:delete_all_schedules) { security_orchestration_policy_configuration.delete_all_schedules }

    it 'deletes all schedules belonging to configuration' do
      delete_all_schedules

      expect(security_orchestration_policy_configuration.rule_schedules).to be_empty
    end
  end

  describe '#active_scan_result_policies' do
    let(:scan_result_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [build(:scan_result_policy)]) }
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    subject(:active_scan_result_policies) { security_orchestration_policy_configuration.active_scan_result_policies }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only enabled policies' do
      expect(active_scan_result_policies.pluck(:enabled).uniq).to contain_exactly(true)
    end

    it 'returns only 5 from all active policies' do
      expect(active_scan_result_policies.count).to be(5)
    end

    context 'when policy configuration is configured for namespace' do
      let(:security_orchestration_policy_configuration) do
        create(:security_orchestration_policy_configuration, :namespace, security_policy_management_project: security_policy_management_project)
      end

      it 'returns empty array' do
        expect(active_scan_result_policies).to match_array([])
      end
    end
  end

  describe '#scan_result_policies' do
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    subject(:scan_result_policies) { security_orchestration_policy_configuration.scan_result_policies }

    it 'returns all scan result policies' do
      expect(scan_result_policies.pluck(:enabled)).to contain_exactly(true, true, false, true, true, true, true, true)
    end
  end

  describe '#project?' do
    subject { security_orchestration_policy_configuration.project? }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq true }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq false }
    end
  end

  describe '#namespace?' do
    subject { security_orchestration_policy_configuration.namespace? }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq false }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq true }
    end
  end

  describe '#source' do
    subject { security_orchestration_policy_configuration.source }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq security_orchestration_policy_configuration.project }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq security_orchestration_policy_configuration.namespace }
    end
  end

  describe '#delete_scan_finding_rules' do
    subject(:delete_scan_finding_rules) { security_orchestration_policy_configuration.delete_scan_finding_rules }

    let(:project) { security_orchestration_policy_configuration.project }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

    before do
      create(:approval_project_rule, :scan_finding, project: project)
      create(:report_approver_rule, :scan_finding, merge_request: merge_request)
    end

    it 'deletes project approval rules' do
      expect { delete_scan_finding_rules }.to change(ApprovalProjectRule, :count).from(1).to(0)
    end

    it 'deletes project approval rules' do
      expect { delete_scan_finding_rules }.to change(ApprovalMergeRequestRule, :count).from(1).to(0)
    end

    context 'without having a project association' do
      let(:project) { create(:project) }
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it 'does not delete project approval rules' do
        expect { delete_scan_finding_rules }.not_to change(ApprovalProjectRule, :count)
      end
    end
  end
end
