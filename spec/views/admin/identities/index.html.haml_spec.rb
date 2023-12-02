# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/identities/index.html.haml', :aggregate_failures do
  include Admin::IdentitiesHelper

  let_it_be(:ldap_user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'ldap-uid') }

  before do
    assign(:user, ldap_user)
    view.lookup_context.prefixes = ['admin/identities']
  end

  context 'without identities' do
    before do
      assign(:identities, [])
    end

    it 'shows table headers' do
      render

      expect(rendered).to include('<th class="gl-border-t-0!">').exactly(5)
      expect(rendered).to include(_('Provider'))
      expect(rendered).to include(s_('Identity|Provider ID'))
      expect(rendered).to include(_('Group'))
      expect(rendered).to include(_('Identifier'))
      expect(rendered).to include(_('Actions'))
    end

    it 'shows information text' do
      render

      expect(rendered).to include('<td colspan="5">').exactly(1)
      expect(rendered).to include(_('This user has no identities'))
    end
  end

  context 'with LDAP identities' do
    before do
      assign(:identities, ldap_user.identities)
    end

    it 'shows exactly 5 columns' do
      render

      expect(rendered).to include('</td>').exactly(5)
    end

    it 'shows identity without provider ID or group' do
      render

      # Provider
      expect(rendered).to include('ldap (ldapmain)')
      # Provider ID
      expect(rendered).to include('data-testid="provider_id_blank"')
      # Group
      expect(rendered).to include('data-testid="saml_group_blank"')
      # Identifier
      expect(rendered).to include('ldap-uid')
    end

    it 'shows edit and delete identity buttons' do
      render

      expect(rendered).to include("aria-label=\"#{_('Edit')}\"")
      expect(rendered).to include("aria-label=\"#{_('Delete identity')}\"")
    end
  end
end
