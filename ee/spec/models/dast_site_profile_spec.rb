# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteProfile, type: :model do
  let_it_be(:project) { create(:project) }

  subject { create(:dast_site_profile, :with_dast_site_validation, project: project) }

  it_behaves_like 'sanitizable', :dast_site_profile, %i[name]

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:dast_site) }
    it { is_expected.to have_many(:secret_variables).class_name('Dast::SiteProfileSecretVariable') }
  end

  describe 'validations' do
    let_it_be(:dast_site) { create(:dast_site, project: project) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:auth_password_field).is_at_most(255) }
    it { is_expected.to validate_length_of(:auth_url).is_at_most(1024).allow_nil }
    it { is_expected.to validate_length_of(:auth_username).is_at_most(255) }
    it { is_expected.to validate_length_of(:auth_username_field).is_at_most(255) }
    it { is_expected.to validate_length_of(:auth_submit_field).is_at_most(255) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:dast_site_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }

    describe '#auth_url' do
      context 'when the auth_uri is nil' do
        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'when the auth_url is not a valid uri' do
        subject { build(:dast_site_profile, project: project, dast_site: dast_site, auth_url: 'hello-world') }

        it 'is not valid' do
          expect(subject).not_to be_valid
        end
      end

      context 'when the auth_url is not public' do
        subject { build(:dast_site_profile, project: project, dast_site: dast_site) }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end
    end

    describe '#excluded_urls' do
      let(:excluded_urls) { [] }

      subject { build(:dast_site_profile, project: project, dast_site: dast_site, excluded_urls: excluded_urls) }

      it { is_expected.to allow_value(Array.new(25, generate(:url))).for(:excluded_urls) }
      it { is_expected.not_to allow_value(Array.new(26, generate(:url))).for(:excluded_urls) }

      context 'when there are some urls that are invalid' do
        let(:excluded_urls) do
          [
            generate(:url),
            generate(:url) + '/' + SecureRandom.alphanumeric(1024),
            'hello-world',
            'hello-world' + '/' + SecureRandom.alphanumeric(1024)
          ]
        end

        it 'is not valid', :aggregate_failures do
          expected_full_messages = [
            "Excluded urls contains invalid URLs (#{excluded_urls[2]}, #{excluded_urls[3]})",
            "Excluded urls contains URLs that exceed the 1024 character limit (#{excluded_urls[1]}, #{excluded_urls[3]})"
          ]

          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to eq(expected_full_messages)
        end
      end
    end

    describe '#project' do
      context 'when the project_id and dast_site.project_id do not match' do
        let_it_be(:dast_site) { create(:dast_site) }

        subject { build(:dast_site_profile, dast_site: dast_site, project: project) }

        it 'is not valid', :aggregate_failures do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include('Project does not match dast_site.project')
        end
      end
    end
  end

  describe 'scopes' do
    describe '.with_dast_site_and_validation' do
      before do
        subject.dast_site_validation.update!(state: :failed)
      end

      it 'eager loads the association', :aggregate_failures do
        subject

        recorder = ActiveRecord::QueryRecorder.new do
          subject.dast_site
          subject.dast_site_validation
        end

        expect(subject.status).to eq('failed') # ensures guard passed
        expect(recorder.count).to be_zero
      end
    end

    describe '.with_name' do
      it 'returns the dast_site_profiles with given name' do
        result = DastSiteProfile.with_name(subject.name)
        expect(result).to eq([subject])
      end
    end
  end

  describe 'enums' do
    let(:target_types) do
      { website: 0, api: 1 }
    end

    let(:scan_methods) do
      { site: 0, openapi: 1, har: 2, postman: 3 }
    end

    it { is_expected.to define_enum_for(:target_type).with_values(**target_types) }

    it { is_expected.to define_enum_for(:scan_method).with_values(**scan_methods).with_prefix }
  end

  describe '.names' do
    it 'returns the names for the DAST site profiles with the given IDs' do
      first_profile = create(:dast_site_profile, name: 'First profile')
      second_profile = create(:dast_site_profile, name: 'Second profile')

      names = described_class.names([first_profile.id, second_profile.id])

      expect(names).to contain_exactly('First profile', 'Second profile')
    end

    context 'when a profile is not found' do
      it 'rescues the error and returns an empty array' do
        names = described_class.names([0])

        expect(names).to be_empty
      end
    end
  end

  describe 'instance methods' do
    describe '#destroy!' do
      context 'when the associated dast_site has no dast_site_profiles' do
        it 'is also destroyed' do
          subject.destroy!

          expect { subject.dast_site.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when the associated dast_site has dast_site_profiles' do
        it 'is not destroyed' do
          create(:dast_site_profile, dast_site: subject.dast_site, project: subject.project)

          subject.destroy!

          expect { subject.dast_site.reload }.not_to raise_error
        end
      end
    end

    describe '#status' do
      context 'when dast_site_validation association does not exist' do
        it 'is none', :aggregate_failures do
          subject.dast_site.update!(dast_site_validation_id: nil)

          expect(subject.dast_site_validation).to be_nil
          expect(subject.status).to eq('none')
        end
      end

      context 'when dast_site_validation association does exist' do
        it 'is dast_site_validation#state' do
          expect(subject.status).to eq(subject.dast_site_validation.state)
        end
      end
    end

    describe '#referenced_in_security_policies' do
      context 'there is no security_orchestration_policy_configuration assigned to project' do
        it 'returns empty array' do
          expect(subject.referenced_in_security_policies).to eq([])
        end
      end

      context 'there is security_orchestration_policy_configuration assigned to project' do
        let(:security_orchestration_policy_configuration) { instance_double(Security::OrchestrationPolicyConfiguration, present?: true, active_policy_names_with_dast_site_profile: ['Policy Name']) }

        before do
          allow(subject.project).to receive(:security_orchestration_policy_configuration).and_return(security_orchestration_policy_configuration)
        end

        it 'calls security_orchestration_policy_configuration.active_policy_names_with_dast_site_profile with profile name' do
          expect(security_orchestration_policy_configuration).to receive(:active_policy_names_with_dast_site_profile).with(subject.name)

          subject.referenced_in_security_policies
        end

        it 'returns the referenced policy name' do
          expect(subject.referenced_in_security_policies).to eq(['Policy Name'])
        end
      end
    end

    describe '#ci_variables' do
      let(:collection) { subject.ci_variables }
      let(:keys) { subject.ci_variables.map { |variable| variable[:key] } }
      let(:excluded_urls) { subject.excluded_urls.join(',') }

      context 'without_dast_submit_field' do
        it 'returns a collection of variables' do
          expected_variables = [
            { key: 'DAST_WEBSITE', value: subject.dast_site.url, public: true, masked: false },
            { key: 'DAST_EXCLUDE_URLS', value: excluded_urls, public: true, masked: false },
            { key: 'DAST_AUTH_URL', value: subject.auth_url, public: true, masked: false },
            { key: 'DAST_USERNAME', value: subject.auth_username, public: true, masked: false },
            { key: 'DAST_USERNAME_FIELD', value: subject.auth_username_field, public: true, masked: false },
            { key: 'DAST_PASSWORD_FIELD', value: subject.auth_password_field, public: true, masked: false },
            { key: 'DAST_API_HTTP_USERNAME', value: subject.auth_username, public: true, masked: false }
          ]

          expect(collection.to_runner_variables).to eq(expected_variables)
        end
      end

      context 'with_dast_submit_field' do
        subject { create(:dast_site_profile, :with_dast_site_validation, :with_dast_submit_field, project: project) }

        it 'returns a collection of variables' do
          expected_variables = [
            { key: 'DAST_WEBSITE', value: subject.dast_site.url, public: true, masked: false },
            { key: 'DAST_EXCLUDE_URLS', value: excluded_urls, public: true, masked: false },
            { key: 'DAST_AUTH_URL', value: subject.auth_url, public: true, masked: false },
            { key: 'DAST_USERNAME', value: subject.auth_username, public: true, masked: false },
            { key: 'DAST_USERNAME_FIELD', value: subject.auth_username_field, public: true, masked: false },
            { key: 'DAST_PASSWORD_FIELD', value: subject.auth_password_field, public: true, masked: false },
            { key: 'DAST_SUBMIT_FIELD', value: subject.auth_submit_field, public: true, masked: false },
            { key: 'DAST_API_HTTP_USERNAME', value: subject.auth_username, public: true, masked: false }
          ]

          expect(collection.to_runner_variables).to eq(expected_variables)
        end
      end

      context 'when target_type=api' do
        subject { build(:dast_site_profile, target_type: :api) }

        it 'returns a collection of variables with api configuration only', :aggregate_failures do
          expect(keys).not_to include('DAST_WEBSITE')
          expect(keys).not_to include('DAST_EXCLUDE_URLS')

          expect(collection).to include(key: 'DAST_API_SPECIFICATION', value: subject.dast_site.url, public: true)
          expect(collection).to include(key: 'DAST_API_HOST_OVERRIDE', value: URI(subject.dast_site.url).host, public: true)
          expect(collection).to include(key: 'DAST_API_EXCLUDE_URLS', value: excluded_urls, public: true)
        end
      end

      context 'when auth is disabled' do
        subject { build(:dast_site_profile, auth_enabled: false) }

        it 'returns a collection of variables excluding any auth variables', :aggregate_failures do
          expect(keys).not_to include('DAST_AUTH_URL', 'DAST_USERNAME', 'DAST_USERNAME_FIELD', 'DAST_PASSWORD_FIELD', 'DAST_SUBMIT_FIELD')
        end
      end

      context 'when excluded_urls is empty' do
        subject { build(:dast_site_profile, excluded_urls: []) }

        it 'is removed from the collection' do
          expect(keys).not_to include('DAST_EXCLUDE_URLS')
          expect(keys).not_to include('DAST_API_EXCLUDE_URLS')
        end
      end

      context 'when a variable is set to nil' do
        subject { build(:dast_site_profile, auth_enabled: true, auth_username_field: nil) }

        it 'is removed from the collection' do
          expect(keys).not_to include('DAST_USERNAME_FIELD')
        end
      end
    end

    describe '#secret_ci_variables' do
      let_it_be(:user) { create(:user, developer_projects: [project]) }

      context 'when user can read secrets' do
        before do
          stub_licensed_features(security_on_demand_scans: true)
        end

        it 'works with policy' do
          expect(Ability.allowed?(user, :read_on_demand_dast_scan, subject)).to be_truthy
        end

        it 'checks the policy' do
          expect(Ability).to receive(:allowed?).with(user, :read_on_demand_dast_scan, subject).and_call_original

          subject.secret_ci_variables(user)
        end

        context 'when there are no secret_variables' do
          it 'returns an empty collection' do
            expect(subject.secret_ci_variables(user).size).to be_zero
          end
        end

        context 'when there are secret_variables' do
          it 'returns a collection containing that variable' do
            variable = create(:dast_site_profile_secret_variable, dast_site_profile: subject)

            expect(subject.secret_ci_variables(user).to_runner_variables).to include(key: variable.key, value: variable.value, public: false, masked: true)
          end

          context 'when password is configured' do
            let(:api_password) { Dast::SiteProfileSecretVariable::API_PASSWORD }

            it 'returns a collection containing api password' do
              variable = create(:dast_site_profile_secret_variable, :password, dast_site_profile: subject)

              expect(subject.secret_ci_variables(user).to_runner_variables).to include(key: api_password, value: variable.value, public: false, masked: true)
            end
          end
        end
      end

      context 'when user cannot read secrets' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an empty collection' do
          create(:dast_site_profile_secret_variable, dast_site_profile: subject)

          expect(subject.secret_ci_variables(user).size).to be_zero
        end
      end
    end

    describe '#ensure_scan_method' do
      let(:target_type) { 'website' }
      let(:scan_method) { 'site' }

      subject { create(:dast_site_profile, scan_method: scan_method, target_type: target_type) }

      context 'when the target_type is website' do
        it 'does not change the scan_method' do
          expect(subject.scan_method).to eq('site')
        end
      end

      context 'when the target type is api' do
        let(:target_type) { 'api' }

        it 'does set the scan_method to openapi' do
          expect(subject.scan_method).to eq('openapi')
        end
      end
    end
  end
end
