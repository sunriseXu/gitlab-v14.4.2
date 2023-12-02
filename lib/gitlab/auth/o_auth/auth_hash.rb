# frozen_string_literal: true

# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module Auth
    module OAuth
      class AuthHash
        attr_reader :auth_hash

        def initialize(auth_hash)
          @auth_hash = auth_hash
        end

        def uid
          @uid ||= Gitlab::Utils.force_utf8(auth_hash.uid.to_s)
        end

        def provider
          @provider ||= auth_hash.provider.to_s
        end

        def name
          @name ||= get_info(:name) || "#{get_info(:first_name)} #{get_info(:last_name)}"
        end

        def username
          @username ||= username_and_email[:username].to_s
        end

        def email
          @email ||= username_and_email[:email].to_s
        end

        def password
          @password ||= Gitlab::Utils.force_utf8(::User.random_password)
        end

        def location
          location = get_info(:address)
          if location.is_a?(Hash)
            [location.locality.presence, location.country.presence].compact.join(', ')
          else
            location
          end
        end

        def has_attribute?(attribute)
          if attribute == :location
            get_info(:address).present?
          else
            get_info(attribute).present?
          end
        end

        private

        def info
          auth_hash['info']
        end

        def coerce_utf8(value)
          value.is_a?(String) ? Gitlab::Utils.force_utf8(value) : value
        end

        def get_info(key)
          coerce_utf8(info[key])
        end

        def provider_config
          Gitlab::Auth::OAuth::Provider.config_for(@provider) || {}
        end

        def provider_args
          @provider_args ||= provider_config['args'].presence || {}
        end

        def get_from_auth_hash_or_info(key)
          coerce_utf8(auth_hash[key]) || get_info(key)
        end

        # Allow for configuring a custom username claim per provider from
        # the auth hash or use the canonical username or nickname fields
        def gitlab_username_claim
          provider_args.dig('gitlab_username_claim')&.to_sym
        end

        def username_claims
          [gitlab_username_claim, :username, :nickname].compact
        end

        def get_username
          username_claims.map { |claim| get_from_auth_hash_or_info(claim) }.find { |name| name.presence }
        end

        def username_and_email
          @username_and_email ||= begin
            username  = get_username
            email     = get_info(:email).presence

            username ||= generate_username(email)             if email
            email    ||= generate_temporarily_email(username) if username

            {
              username: username,
              email: email
            }
          end
        end

        # Get the first part of the email address (before @)
        # In addition in removes illegal characters
        def generate_username(email)
          email.match(/^[^@]*/)[0].mb_chars.unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/, '').to_s
        end

        def generate_temporarily_email(username)
          "temp-email-for-oauth-#{username}@gitlab.localhost"
        end
      end
    end
  end
end

Gitlab::Auth::OAuth::AuthHash.prepend_mod_with('Gitlab::Auth::OAuth::AuthHash')
