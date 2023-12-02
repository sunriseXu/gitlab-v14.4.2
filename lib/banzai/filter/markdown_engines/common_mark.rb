# frozen_string_literal: true

# `CommonMark` markdown engine for GitLab's Banzai markdown filter.
# This module is used in Banzai::Filter::MarkdownFilter.
# Used gem is `commonmarker` which is a ruby wrapper for libcmark (CommonMark parser)
# including GitHub's GFM extensions.
# We now utilize the renderer built in `C`, rather than the ruby based renderer.
# Homepage: https://github.com/gjtorikian/commonmarker
module Banzai
  module Filter
    module MarkdownEngines
      class CommonMark
        EXTENSIONS = [
          :autolink,      # provides support for automatically converting URLs to anchor tags.
          :strikethrough, # provides support for strikethroughs.
          :table          # provides support for tables.
        ].freeze

        PARSE_OPTIONS = [
          :FOOTNOTES,                  # parse footnotes.
          :STRIKETHROUGH_DOUBLE_TILDE, # parse strikethroughs by double tildes (as redcarpet does).
          :VALIDATE_UTF8               # replace illegal sequences with the replacement character U+FFFD.
        ].freeze

        RENDER_OPTIONS = [
          :GITHUB_PRE_LANG,  # use GitHub-style <pre lang> for fenced code blocks.
          :FOOTNOTES,        # render footnotes.
          :FULL_INFO_STRING, # include full info strings of code blocks in separate attribute.
          :UNSAFE            # allow raw/custom HTML and unsafe links.
        ].freeze

        def initialize(context)
          @context = context
        end

        def render(text)
          CommonMarker.render_html(text, render_options, EXTENSIONS)
        end

        private

        def render_options
          @context[:no_sourcepos] ? render_options_no_sourcepos : render_options_sourcepos
        end

        def render_options_no_sourcepos
          RENDER_OPTIONS
        end

        def render_options_sourcepos
          render_options_no_sourcepos + [
            :SOURCEPOS # enable embedding of source position information
          ].freeze
        end
      end
    end
  end
end
