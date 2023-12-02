# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GEO Nodes', :geo do
  include ::EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:geo_primary) { create(:geo_node, :primary) }
  let_it_be(:geo_secondary) { create(:geo_node) }

  context 'Geo Secondary Node' do
    let(:project) { create(:project) }

    before do
      stub_current_geo_node(geo_secondary)

      project.add_maintainer(user)
      sign_in(user)
    end

    describe "showing Flash Info Message" do
      it 'on dashboard' do
        visit root_dashboard_path
        expect(page).to have_content 'You are on a secondary, read-only Geo site. If you want to make changes, you must visit the primary site.'
        expect(page).to have_content 'Go to the primary site'
      end

      it 'on project overview' do
        visit project_path(project)
        expect(page).to have_content 'You are on a secondary, read-only Geo site. If you want to make changes, you must visit the primary site.'
        expect(page).to have_content 'Go to the primary site'
      end
    end
  end

  context 'Primary Geo Node' do
    let(:admin_user) { create(:user, :admin) }

    before do
      stub_current_geo_node(geo_primary)
      stub_licensed_features(geo: true)

      sign_in(admin_user)
      gitlab_enable_admin_mode_sign_in(admin_user)
    end

    describe 'Geo Nodes admin screen' do
      it "has a 'Full details' button on listed secondary geo nodes pointing to correct URL", :js do
        visit admin_geo_nodes_path

        expect(page).to have_content(geo_primary.url)
        expect(page).to have_content(geo_secondary.url)

        wait_for_requests

        expected_url = File.join(geo_secondary.url, "/admin/geo/sites/#{geo_secondary.id}/replication/lfs_objects")

        expect(all('.geo-node-details-grid-columns').last).to have_link('Full details', href: expected_url)
      end

      context 'Node Filters', :js do
        it 'defaults to the All tab when a status query is not already set' do
          visit admin_geo_nodes_path
          tab_count = find('[data-testid="geo-sites-filter"] .active .badge').text.to_i
          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(find('[data-testid="geo-sites-filter"] .active')).to have_content('All')
          expect(results_count).to be(tab_count)
        end

        it 'sets the correct tab when a status query is already set' do
          visit admin_geo_nodes_path(status: 'unknown')
          tab_count = find('[data-testid="geo-sites-filter"] .active .badge').text.to_i
          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(find('[data-testid="geo-sites-filter"] .active')).not_to have_content('All')
          expect(find('[data-testid="geo-sites-filter"] .active')).to have_content('Unknown')
          expect(results_count).to be(tab_count)
        end

        it 'properly updates the query and sets the tab when a new one is clicked' do
          visit admin_geo_nodes_path
          tab_count = find('[data-testid="geo-sites-filter"] .active .badge').text.to_i
          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(find('[data-testid="geo-sites-filter"] .active')).to have_content('All')
          expect(results_count).to be(tab_count)

          click_link 'Unknown'

          wait_for_requests
          tab_count = find('[data-testid="geo-sites-filter"] .active .badge').text.to_i
          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(find('[data-testid="geo-sites-filter"] .active')).not_to have_content('All')
          expect(find('[data-testid="geo-sites-filter"] .active')).to have_content('Unknown')
          expect(page).to have_current_path(admin_geo_nodes_path(status: 'unknown'))
          expect(results_count).to be(tab_count)
        end

        it 'properly updates the query and filters the nodes when a search is inputed' do
          visit admin_geo_nodes_path

          fill_in 'Filter Geo sites', with: geo_secondary.name
          wait_for_requests

          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(results_count).to be(1)
          expect(page).to have_current_path(admin_geo_nodes_path(search: geo_secondary.name))
        end

        it 'properly sets the search when a search query is already set' do
          visit admin_geo_nodes_path(search: geo_secondary.name)

          results_count = page.all('[data-testid="primary-nodes"]').length + page.all('[data-testid="secondary-nodes"]').length

          expect(find('input[placeholder="Filter Geo sites"]').value).to eq(geo_secondary.name)
          expect(results_count).to be(1)
        end

        it 'properly handles both a status and search query' do
          visit admin_geo_nodes_path(status: 'unknown', search: geo_secondary.name)

          results = page.all(:xpath, '//div[@data-testid="primary-nodes"] | //div[@data-testid="secondary-nodes"]')

          expect(find('[data-testid="geo-sites-filter"] .active')).to have_content('Unknown')
          expect(find("input[placeholder='Filter Geo sites']").value).to eq(geo_secondary.name)
          expect(results.length).to be(1)
          expect(results[0]).to have_content(geo_secondary.name)
          expect(results[0]).to have_content('Unknown')
        end
      end
    end
  end
end
