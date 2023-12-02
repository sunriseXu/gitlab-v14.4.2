# frozen_string_literal: true

module EE
  module Member
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      state_machine :state, initial: :active do
        event :wait do
          transition active: :awaiting, unless: :last_owner?
        end

        event :activate do
          transition awaiting: :active, if: :has_capacity_left?
        end

        state :awaiting, value: ::Member::STATE_AWAITING
        state :active, value: ::Member::STATE_ACTIVE
      end
      scope :awaiting, -> { where(state: ::Member::STATE_AWAITING) }
      scope :non_awaiting, -> { where.not(state: ::Member::STATE_AWAITING) }

      scope :banned, -> do
        joins("INNER JOIN namespace_bans
               ON namespace_bans.user_id = members.user_id
               AND namespace_bans.namespace_id = members.member_namespace_id")
      end

      before_create :set_membership_activation

      scope :with_csv_entity_associations, -> do
        includes(:user, source: [:route, :parent])
      end

      scope :distinct_awaiting_or_invited_for_group, -> (group) do
        awaiting
        .or(::Member.invite)
        .in_hierarchy(group)
        .select('DISTINCT ON (members.user_id, members.invite_email) members.*')
        .includes(:user)
        .order(:user_id, :invite_email)
      end
    end

    override :notification_service
    def notification_service
      if ldap
        # LDAP users shouldn't receive notifications about membership changes
        ::EE::NullNotificationService.new
      else
        super
      end
    end

    def sso_enforcement
      unless ::Gitlab::Auth::GroupSaml::MembershipEnforcer.new(group).can_add_user?(user)
        errors.add(:user, 'is not linked to a SAML account')
      end
    end

    # The method is exposed in the API as is_using_seat
    # in ee/lib/ee/api/entities.rb
    #
    # rubocop: disable Naming/PredicateName
    def is_using_seat
      return user.using_gitlab_com_seat?(source) if ::Gitlab.com?

      user.using_license_seat?
    end
    # rubocop: enable Naming/PredicateName

    def source_kind
      source.is_a?(Group) && source.parent.present? ? 'Sub group' : source.class.to_s
    end

    def group_has_domain_limitations?
      return false unless group

      group.licensed_feature_available?(:group_allowed_email_domains) && group_allowed_email_domains.any?
    end

    def group_domain_limitations
      return unless group

      if user
        return if user.project_bot?

        validate_users_email
        validate_email_verified
      else
        validate_invitation_email
      end
    end

    def group_saml_identity(root_ancestor: false)
      saml_group = root_ancestor ? group.root_ancestor : group

      return unless saml_group.saml_provider

      if user.group_saml_identities.loaded?
        user.group_saml_identities.detect { |i| i.saml_provider_id == saml_group.saml_provider.id }
      else
        user.group_saml_identities.find_by(saml_provider: saml_group.saml_provider)
      end
    end

    private

    def group_allowed_email_domains
      return [] unless group

      group.root_ancestor_allowed_email_domains
    end

    def validate_users_email
      return if matches_at_least_one_group_allowed_email_domain?(user.email)

      errors.add(:user, email_does_not_match_any_allowed_domains(user.email))
    end

    def validate_invitation_email
      return if matches_at_least_one_group_allowed_email_domain?(invite_email)

      errors.add(:invite_email, email_does_not_match_any_allowed_domains(invite_email))
    end

    def validate_email_verified
      return if user.primary_email_verified?

      return if group_saml_identity(root_ancestor: true).present?
      return if group.root_ancestor.scim_identities.for_user(user).exists?

      errors.add(:user, email_not_verified)
    end

    def email_does_not_match_any_allowed_domains(email)
      msg_1 = signup_email_invalid_message

      msg_2 = error_message[created_by_key][:group_setting]

      [msg_1, msg_2].join(' ')
    end

    def matches_at_least_one_group_allowed_email_domain?(email)
      group_allowed_email_domains.any? do |allowed_email_domain|
        allowed_email_domain.email_matches_domain?(email)
      end
    end

    def email_not_verified
      _("email '%{email}' is not a verified email." % { email: user.email })
    end

    def set_membership_activation
      self.state = ::Member::STATE_AWAITING unless has_capacity_left?
    end

    def last_owner?
      source.root_ancestor.last_owner?(self.user)
    end

    def has_capacity_left?
      source.root_ancestor.capacity_left_for_user?(user)
    end
  end
end
