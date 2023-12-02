# frozen_string_literal: true

module QA
  module Page
    module File
      class Edit < Page::Base
        include Shared::CommitMessage
        include Shared::CommitButton
        include Shared::Editor

        view 'app/assets/javascripts/editor/components/source_editor_toolbar_button.vue' do
          element :editor_toolbar_button
        end

        view 'app/views/projects/blob/_editor.html.haml' do
          element :source_editor_preview_container
        end

        def has_markdown_preview?(component, content)
          within_element(:source_editor_preview_container) do
            has_css?(component, exact_text: content)
          end
        end

        def wait_for_markdown_preview(component, content)
          return if has_markdown_preview?(component, content)

          raise ElementNotFound, %("Couldn't find #{component} element with content '#{content}')
        end

        def click_editor_toolbar
          click_element(:editor_toolbar_button)
        end
      end
    end
  end
end
