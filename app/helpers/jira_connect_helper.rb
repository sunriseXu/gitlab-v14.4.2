# frozen_string_literal: true

module JiraConnectHelper
  def jira_connect_app_data(subscriptions, installation)
    skip_groups = subscriptions.map(&:namespace_id)

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions: subscriptions.map { |s| serialize_subscription(s) }.to_json,
      add_subscriptions_path: jira_connect_subscriptions_path,
      subscriptions_path: jira_connect_subscriptions_path(format: :json),
      users_path: current_user ? nil : jira_connect_users_path, # users_path is used to determine if user is signed in
      gitlab_user_path: current_user ? user_path(current_user) : nil,
      oauth_metadata: Feature.enabled?(:jira_connect_oauth, current_user) ? jira_connect_oauth_data(installation).to_json : nil
    }
  end

  private

  def jira_connect_oauth_data(installation)
    oauth_instance_url = installation.oauth_authorization_url

    oauth_authorize_path = oauth_authorization_path(
      client_id: Gitlab::CurrentSettings.jira_connect_application_key,
      response_type: 'code',
      scope: 'api',
      redirect_uri: jira_connect_oauth_callbacks_url,
      state: oauth_state
    )

    {
      oauth_authorize_url: Gitlab::Utils.append_path(oauth_instance_url, oauth_authorize_path),
      oauth_token_path: oauth_token_path,
      state: oauth_state,
      oauth_token_payload: {
        grant_type: :authorization_code,
        client_id: Gitlab::CurrentSettings.jira_connect_application_key,
        redirect_uri: jira_connect_oauth_callbacks_url
      }
    }
  end

  def oauth_state
    @oauth_state ||= SecureRandom.hex(32)
  end

  def serialize_subscription(subscription)
    {
      group: {
        name: subscription.namespace.name,
        avatar_url: subscription.namespace.avatar_url,
        full_name: subscription.namespace.full_name,
        description: subscription.namespace.description
      },
      created_at: subscription.created_at,
      unlink_path: jira_connect_subscription_path(subscription)
    }
  end
end
