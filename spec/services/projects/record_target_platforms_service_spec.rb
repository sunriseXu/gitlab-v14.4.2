# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RecordTargetPlatformsService, '#execute' do
  let_it_be(:project) { create(:project) }

  let(:detector_service) { Projects::AppleTargetPlatformDetectorService }

  subject(:execute) { described_class.new(project, detector_service).execute }

  context 'when detector returns target platform values' do
    let(:detector_result) { [:ios, :osx] }
    let(:service_result) { detector_result.map(&:to_s) }

    before do
      double = instance_double(detector_service, execute: detector_result)
      allow(detector_service).to receive(:new) { double }
    end

    shared_examples 'saves and returns detected target platforms' do
      it 'creates a new setting record for the project', :aggregate_failures do
        expect { execute }.to change { ProjectSetting.count }.from(0).to(1)
        expect(ProjectSetting.last.target_platforms).to match_array(service_result)
      end

      it 'returns the array of stored target platforms' do
        expect(execute).to match_array service_result
      end
    end

    it_behaves_like 'saves and returns detected target platforms'

    context 'when detector returns a non-array value' do
      let(:detector_service) { Projects::AndroidTargetPlatformDetectorService }
      let(:detector_result) { :android }
      let(:service_result) { [detector_result.to_s] }

      it_behaves_like 'saves and returns detected target platforms'
    end

    context 'when a project has an existing setting record' do
      before do
        create(:project_setting, project: project, target_platforms: saved_target_platforms)
      end

      def project_setting
        ProjectSetting.find_by_project_id(project.id)
      end

      context 'when target platforms changed' do
        let(:saved_target_platforms) { %w(tvos) }

        it 'updates' do
          expect { execute }.to change { project_setting.target_platforms }.from(%w(tvos)).to(%w(ios osx))
        end

        it { is_expected.to match_array %w(ios osx) }
      end

      context 'when target platforms are the same' do
        let(:saved_target_platforms) { %w(osx ios) }

        it 'does not update' do
          expect { execute }.not_to change { project_setting.updated_at }
        end
      end
    end

    describe 'Build iOS guide email experiment' do
      shared_examples 'tracks experiment assignment event' do
        it 'tracks the assignment event', :experiment do
          expect(experiment(:build_ios_app_guide_email))
            .to track(:assignment)
            .with_context(project: project)
            .on_next_instance

          execute
        end
      end

      context 'experiment candidate' do
        before do
          stub_experiments(build_ios_app_guide_email: :candidate)
        end

        it 'executes a Projects::InProductMarketingCampaignEmailsService' do
          service_double = instance_double(Projects::InProductMarketingCampaignEmailsService, execute: true)

          expect(Projects::InProductMarketingCampaignEmailsService)
            .to receive(:new).with(project, Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE)
            .and_return service_double
          expect(service_double).to receive(:execute)

          execute
        end

        it_behaves_like 'tracks experiment assignment event'
      end

      shared_examples 'does not send email' do
        it 'does not execute a Projects::InProductMarketingCampaignEmailsService' do
          expect(Projects::InProductMarketingCampaignEmailsService).not_to receive(:new)

          execute
        end
      end

      context 'experiment control' do
        before do
          stub_experiments(build_ios_app_guide_email: :control)
        end

        it_behaves_like 'does not send email'
        it_behaves_like 'tracks experiment assignment event'
      end

      context 'when project is not an iOS project' do
        let(:detector_service) { Projects::AppleTargetPlatformDetectorService }
        let(:detector_result) { :android }

        before do
          stub_experiments(build_ios_app_guide_email: :candidate)
        end

        it_behaves_like 'does not send email'

        it 'does not track experiment assignment event', :experiment do
          expect(experiment(:build_ios_app_guide_email))
            .not_to track(:assignment)

          execute
        end
      end
    end
  end

  context 'when detector does not return any target platform values' do
    before do
      double = instance_double(Projects::AppleTargetPlatformDetectorService, execute: [])
      allow(Projects::AppleTargetPlatformDetectorService).to receive(:new).with(project) { double }
    end

    it 'does nothing' do
      expect { execute }.not_to change { ProjectSetting.count }
    end

    it { is_expected.to be_nil }
  end
end
