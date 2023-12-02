# frozen_string_literal: true

RSpec.shared_examples 'edits content using the content editor' do
  let(:content_editor_testid) { '[data-testid="content-editor"] [contenteditable].ProseMirror' }

  def switch_to_content_editor
    find('[data-testid="toggle-editing-mode-button"] label', text: 'Rich text').click
  end

  def type_in_content_editor(keys)
    find(content_editor_testid).send_keys keys
  end

  def open_insert_media_dropdown
    page.find('svg[data-testid="media-icon"]').click
  end

  def set_source_editor_content(content)
    find('.js-gfm-input').set content
  end

  def expect_formatting_menu_to_be_visible
    expect(page).to have_css('[data-testid="formatting-bubble-menu"]')
  end

  def expect_formatting_menu_to_be_hidden
    expect(page).not_to have_css('[data-testid="formatting-bubble-menu"]')
  end

  def expect_media_bubble_menu_to_be_visible
    expect(page).to have_css('[data-testid="media-bubble-menu"]')
  end

  def upload_asset(fixture_name)
    attach_file('content_editor_image', Rails.root.join('spec', 'fixtures', fixture_name), make_visible: true)
  end

  describe 'formatting bubble menu' do
    it 'shows a formatting bubble menu for a regular paragraph and headings' do
      switch_to_content_editor

      expect(page).to have_css(content_editor_testid)

      type_in_content_editor 'Typing text in the content editor'
      type_in_content_editor [:shift, :left]

      expect_formatting_menu_to_be_visible

      type_in_content_editor [:right, :right, :enter, '## Heading']

      expect_formatting_menu_to_be_hidden

      type_in_content_editor [:shift, :left]

      expect_formatting_menu_to_be_visible
    end
  end

  describe 'media elements bubble menu' do
    before do
      switch_to_content_editor

      open_insert_media_dropdown
    end

    def test_displays_media_bubble_menu(media_element_selector, fixture_file)
      upload_asset fixture_file

      wait_for_requests

      expect(page).to have_css(media_element_selector)

      page.find(media_element_selector).click

      expect_formatting_menu_to_be_hidden
      expect_media_bubble_menu_to_be_visible
    end

    it 'displays correct media bubble menu for images', :js do
      test_displays_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'dk.png'
    end

    it 'displays correct media bubble menu for video', :js do
      test_displays_media_bubble_menu '[data-testid="content_editor_editablebox"] video', 'video_sample.mp4'
    end
  end

  describe 'code block' do
    before do
      visit(profile_preferences_path)

      find('.syntax-theme').choose('Dark')

      wait_for_requests

      page.go_back
      refresh
      switch_to_content_editor
    end

    it 'applies theme classes to code blocks' do
      expect(page).not_to have_css('.content-editor-code-block.code.highlight.dark')

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```js ' # trigger input rule
      type_in_content_editor 'var a = 0'

      expect(page).to have_css('.content-editor-code-block.code.highlight.dark')
    end
  end

  describe 'code block bubble menu' do
    before do
      switch_to_content_editor
    end

    it 'shows a code block bubble menu for a code block' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```js ' # trigger input rule
      type_in_content_editor 'var a = 0'
      type_in_content_editor [:shift, :left]

      expect_formatting_menu_to_be_hidden
      expect(page).to have_css('[data-testid="code-block-bubble-menu"]')
    end

    it 'sets code block type to "javascript" for `js`' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```js '
      type_in_content_editor 'var a = 0'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Javascript')
    end

    it 'sets code block type to "Custom (nomnoml)" for `nomnoml`' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```nomnoml '
      type_in_content_editor 'test'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Custom (nomnoml)')
    end
  end

  describe 'mermaid diagram' do
    before do
      switch_to_content_editor

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```mermaid '
      type_in_content_editor ['graph TD;', :enter, '  JohnDoe12 --> HelloWorld34']
    end

    it 'renders and updates the diagram correctly in a sandboxed iframe' do
      iframe = find(content_editor_testid).find('iframe')
      expect(iframe['src']).to include('/-/sandbox/mermaid')

      within_frame(iframe) do
        expect(find('svg').text).to include('JohnDoe12')
        expect(find('svg').text).to include('HelloWorld34')
      end

      expect(iframe['height'].to_i).to be > 100

      find(content_editor_testid).send_keys [:enter, '  JaneDoe34 --> HelloWorld56']

      within_frame(iframe) do
        page.has_content?('JaneDoe34')

        expect(find('svg').text).to include('JaneDoe34')
        expect(find('svg').text).to include('HelloWorld56')
      end
    end

    it 'toggles the diagram when preview button is clicked' do
      find('[data-testid="preview-diagram"]').click

      expect(find(content_editor_testid)).not_to have_selector('iframe')

      find('[data-testid="preview-diagram"]').click

      iframe = find(content_editor_testid).find('iframe')

      within_frame(iframe) do
        expect(find('svg').text).to include('JohnDoe12')
        expect(find('svg').text).to include('HelloWorld34')
      end
    end
  end
end
