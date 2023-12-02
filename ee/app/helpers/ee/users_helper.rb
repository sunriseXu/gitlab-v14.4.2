# frozen_string_literal: true

module EE
  module UsersHelper
    extend ::Gitlab::Utils::Override

    override :display_public_email?
    def display_public_email?(user)
      return false if user.public_email.blank?
      return true unless user.provisioned_by_group

      !::Feature.enabled?(:hide_public_email_on_profile, user.provisioned_by_group)
    end

    def users_sentence(users, link_class: nil)
      users.map { |user| link_to(user.name, user, class: link_class) }.to_sentence.html_safe
    end

    def trials_link_url
      new_trial_registration_path(glm_source: 'gitlab.com', glm_content: 'top-right-dropdown')
    end

    def user_badges_in_admin_section(user)
      super(user).tap do |badges|
        if !::Gitlab.com? && user.using_license_seat?
          it_s_you_index = badges.index { |badge| badge[:text] == "It's you!" } || -1

          badges.insert(it_s_you_index, { text: s_('AdminUsers|Is using seat'), variant: 'neutral' })
        end
      end
    end

    private

    def trials_allowed?(user)
      return unless user
      return unless ::Gitlab.com?

      Rails.cache.fetch(['users', user.id, 'trials_allowed?'], expires_in: 10.minutes) do
        !user.has_paid_namespace? && user.owns_group_without_trial?
      end
    end
  end
end
