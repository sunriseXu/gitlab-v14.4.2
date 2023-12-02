# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Invitations, 'EE Invitations' do
  include GroupAPIHelpers

  let_it_be(:admin) { create(:user, :admin, email: 'admin@example.com') }
  let_it_be(:group, reload: true) { create(:group) }

  let(:url) { "/groups/#{group.id}/invitations" }
  let(:invite_email) { 'restricted@example.org' }

  shared_examples 'restricted email error' do |message, code|
    it 'returns an http error response and the validation message' do
      post api(url, admin),
      params: { email: invite_email, access_level: Member::MAINTAINER }

      expect(response).to have_gitlab_http_status(code)
      expect(json_response['message'][invite_email]).to eq message
    end
  end

  shared_examples 'admin signup restrictions email error - denylist' do |message, code|
    before do
      stub_application_setting(domain_denylist_enabled: true)
      stub_application_setting(domain_denylist: ['example.org'])
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'admin signup restrictions email error - allowlist' do |message, code|
    before do
      stub_application_setting(domain_allowlist: ['example.com'])
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'admin signup restrictions email error - email restrictions' do |message, code|
    before do
      stub_application_setting(email_restrictions_enabled: true)
      stub_application_setting(email_restrictions: '([\+]|\b(\w*example.org\w*)\b)')
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'member creation audit event' do
    it 'creates an audit event while creating a new member' do
      params = { email: 'example1@example.com', access_level: Member::DEVELOPER }

      expect do
        post api(url, admin), params: params

        expect(response).to have_gitlab_http_status(:created)
      end.to change { AuditEvent.count }.by(1)
    end

    it 'does not create audit event if creating a new member fails' do
      params = { email: '_bogus_', access_level: Member::DEVELOPER }

      expect do
        post api(url, admin), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end.not_to change { AuditEvent.count }
    end
  end

  describe 'POST /groups/:id/invitations' do
    it_behaves_like 'member creation audit event'
    it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created

    context 'when the group is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error - allowlist', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Allowed domains for sign-ups&#39;.", :created
      it_behaves_like 'admin signup restrictions email error - email restrictions', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Email restrictions for sign-ups&#39;.", :created
    end

    context 'when the group is restricted by group signup restriction - allowed domains for signup' do
      before do
        stub_licensed_features(group_allowed_email_domains: true)
        create(:allowed_email_domain, group: group, domain: 'example.com')
      end

      it_behaves_like 'restricted email error', "The member's email address is not allowed for this group. Go to the group’s &#39;Settings &gt; General&#39; page, and check &#39;Restrict membership by email domain&#39;.", :success
    end
  end

  describe 'POST /projects/:id/invitations' do
    let_it_be(:project) { create(:project, namespace: group) }

    let(:url) { "/projects/#{project.id}/invitations" }

    it_behaves_like 'member creation audit event'

    context 'with group membership locked' do
      before do
        group.update!(membership_lock: true)
      end

      it 'returns an error and exception message when group membership lock is enabled' do
        params = { email: 'example1@example.com', access_level: Member::DEVELOPER }

        post api(url, admin), params: params

        expect(json_response['message']).to eq 'Members::CreateService::MembershipLockedError'
        expect(json_response['status']).to eq 'error'
      end
    end

    context 'when the project is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created
      context 'when the group is restricted by admin signup restrictions' do
        it_behaves_like 'admin signup restrictions email error - allowlist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Allowed domains for sign-ups&#39;.", :created
        it_behaves_like 'admin signup restrictions email error - email restrictions', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Email restrictions for sign-ups&#39;.", :created
      end
    end
  end

  context 'group with LDAP group link' do
    include LdapHelpers

    let(:group) { create(:group_with_ldap_group_link, :public) }
    let(:owner) { create(:user) }
    let(:developer) { create(:user) }
    let(:invite) { create(:group_member, :invited, source: group, user: developer) }

    before do
      create(:group_member, :owner, group: group, user: owner)
      stub_ldap_setting(enabled: true)
      stub_application_setting(lock_memberships_to_ldap: true)
    end

    describe 'POST /groups/:id/invitations' do
      it 'returns a forbidden response' do
        post api("/groups/#{group.id}/invitations", owner), params: { email: developer.email, access_level: Member::DEVELOPER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'PUT /groups/:id/invitations/:email' do
      it 'returns a forbidden response' do
        put api("/groups/#{group.id}/invitations/#{invite.invite_email}", owner), params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'DELETE /groups/:id/invitations/:email' do
      it 'returns a forbidden response' do
        delete api("/groups/#{group.id}/invitations/#{invite.invite_email}", owner)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
