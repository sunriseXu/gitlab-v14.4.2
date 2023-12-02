# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper do
  describe '#jira_connect_app_data' do
    let_it_be(:installation) { create(:jira_connect_installation) }
    let_it_be(:subscription) { create(:jira_connect_subscription) }

    let(:user) { create(:user) }
    let(:client_id) { '123' }

    before do
      stub_application_setting(jira_connect_application_key: client_id)
    end

    subject { helper.jira_connect_app_data([subscription], installation) }

    context 'user is not logged in' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
        allow(Gitlab).to receive_message_chain('config.gitlab.url') { 'http://test.host' }
      end

      it 'includes Jira Connect app attributes' do
        is_expected.to include(
          :groups_path,
          :add_subscriptions_path,
          :subscriptions_path,
          :users_path,
          :subscriptions,
          :gitlab_user_path
        )
      end

      it 'assigns users_path with value' do
        expect(subject[:users_path]).to eq(jira_connect_users_path)
      end

      context 'with oauth_metadata' do
        let(:oauth_metadata) { helper.jira_connect_app_data([subscription], installation)[:oauth_metadata] }

        subject(:parsed_oauth_metadata) { Gitlab::Json.parse(oauth_metadata).deep_symbolize_keys }

        it 'assigns oauth_metadata' do
          expect(parsed_oauth_metadata).to include(
            oauth_authorize_url: start_with('http://test.host/oauth/authorize?'),
            oauth_token_path: '/oauth/token',
            state: %r/[a-z0-9.]{32}/,
            oauth_token_payload: hash_including(
              grant_type: 'authorization_code',
              client_id: client_id,
              redirect_uri: 'http://test.host/-/jira_connect/oauth_callbacks'
            )
          )
        end

        it 'includes oauth_authorize_url with all params' do
          params = Rack::Utils.parse_nested_query(URI.parse(parsed_oauth_metadata[:oauth_authorize_url]).query)

          expect(params).to include(
            'client_id' => client_id,
            'response_type' => 'code',
            'scope' => 'api',
            'redirect_uri' => 'http://test.host/-/jira_connect/oauth_callbacks',
            'state' => parsed_oauth_metadata[:state]
          )
        end

        context 'jira_connect_oauth feature is disabled' do
          before do
            stub_feature_flags(jira_connect_oauth: false)
          end

          it 'does not assign oauth_metadata' do
            expect(oauth_metadata).to be_nil
          end
        end

        context 'with self-managed instance' do
          let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://gitlab.example.com') }

          it 'points urls to the self-managed instance' do
            expect(parsed_oauth_metadata).to include(
              oauth_authorize_url: start_with('https://gitlab.example.com/oauth/authorize?'),
              oauth_token_path: '/oauth/token'
            )
          end

          context 'and jira_connect_oauth_self_managed feature is disabled' do
            before do
              stub_feature_flags(jira_connect_oauth_self_managed: false)
            end

            it 'does not point urls to the self-managed instance' do
              expect(parsed_oauth_metadata).not_to include(
                oauth_authorize_url: start_with('https://gitlab.example.com/oauth/authorize?'),
                oauth_token_path: 'https://gitlab.example.com/oauth/token'
              )
            end
          end
        end
      end

      it 'passes group as "skip_groups" param' do
        skip_groups_param = CGI.escape('skip_groups[]')

        expect(subject[:groups_path]).to include("#{skip_groups_param}=#{subscription.namespace.id}")
      end

      it 'assigns gitlab_user_path to nil' do
        expect(subject[:gitlab_user_path]).to be_nil
      end
    end

    context 'user is logged in' do
      before do
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'assigns users_path to nil' do
        expect(subject[:users_path]).to be_nil
      end

      it 'assigns gitlab_user_path correctly' do
        expect(subject[:gitlab_user_path]).to eq(user_path(user))
      end
    end
  end
end
