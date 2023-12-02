# frozen_string_literal: true

RSpec.shared_examples 'labels sidebar widget' do
  context 'editing labels' do
    let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
    let_it_be(:stretch)     { create(:label, project: project, name: 'Stretch') }
    let_it_be(:xss_label) { create(:label, project: project, title: '&lt;script&gt;alert("xss");&lt;&#x2F;script&gt;') }

    let(:labels_widget) { find('[data-testid="sidebar-labels"]') }

    before do
      page.within(labels_widget) do
        click_on 'Edit'
      end

      wait_for_all_requests
    end

    it 'shows labels list in the dropdown' do
      expect(labels_widget.find('.gl-new-dropdown-contents')).to have_selector('li.gl-new-dropdown-item', count: 4)
    end

    it 'adds a label' do
      within(labels_widget) do
        adds_label(stretch)

        page.within('[data-testid="value-wrapper"]') do
          expect(page).to have_content(stretch.name)
        end
      end
    end

    it 'removes a label' do
      within(labels_widget) do
        adds_label(stretch)
        page.within('[data-testid="value-wrapper"]') do
          expect(page).to have_content(stretch.name)
        end

        click_on 'Remove label'

        wait_for_requests

        page.within('[data-testid="value-wrapper"]') do
          expect(page).not_to have_content(stretch.name)
        end
      end
    end

    it 'adds first label by pressing enter when search' do
      within(labels_widget) do
        page.within('[data-testid="value-wrapper"]') do
          expect(page).not_to have_content(development.name)
        end

        fill_in 'Search', with: 'Devel'
        expect(page).to have_css('.labels-fetch-loading')
        wait_for_all_requests

        expect(page).to have_css('[data-testid="dropdown-content"] .gl-new-dropdown-item')
        expect(page.all(:css, '[data-testid="dropdown-content"] .gl-new-dropdown-item').length).to eq(1)

        find_field('Search').native.send_keys(:enter)
        click_button 'Close'
        wait_for_requests

        page.within('[data-testid="value-wrapper"]') do
          expect(page).to have_content(development.name)
        end
      end
    end

    it 'escapes XSS when viewing issuable labels' do
      page.within(labels_widget) do
        expect(page).to have_content '<script>alert("xss");</script>'
      end
    end

    it 'shows option to create a label' do
      page.within(labels_widget) do
        expect(page).to have_content 'Create'
      end
    end

    context 'creating a label', :js do
      before do
        page.within(labels_widget) do
          page.find('[data-testid="create-label-button"]').click
        end
      end

      it 'shows dropdown switches to "create label" section' do
        page.within(labels_widget) do
          expect(page.find('[data-testid="dropdown-header"]')).to have_content 'Create'
        end
      end

      it 'creates new label' do
        page.within(labels_widget) do
          fill_in 'Name new label', with: 'wontfix'
          page.find('.suggest-colors a', match: :first).click
          page.find('button', text: 'Create').click
          wait_for_requests

          expect(page).to have_content 'wontfix'
        end
      end

      it 'shows error message if label title is taken' do
        page.within(labels_widget) do
          fill_in 'Name new label', with: development.title
          page.find('.suggest-colors a', match: :first).click
          page.find('button', text: 'Create').click
          wait_for_requests

          page.within('.dropdown-input') do
            expect(page.find('.gl-alert')).to have_content 'Title'
          end
        end
      end
    end
  end

  def adds_label(label)
    click_button label.name
    click_button 'Close'

    wait_for_requests
  end
end
