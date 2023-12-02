# frozen_string_literal: true

module Gitlab
  module Nav
    class TopNavViewModelBuilder
      def initialize
        @menu_builder = ::Gitlab::Nav::TopNavMenuBuilder.new
        @views = {}
        @shortcuts = []
      end

      # Using delegate hides the stacktrace for some errors, so we choose to be explicit.
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62047#note_579031091
      def add_primary_menu_item(**args)
        @menu_builder.add_primary_menu_item(**args)
      end

      def add_secondary_menu_item(**args)
        @menu_builder.add_secondary_menu_item(**args)
      end

      def add_shortcut(**args)
        item = ::Gitlab::Nav::TopNavMenuItem.build(**args)

        @shortcuts.push(item)
      end

      def add_primary_menu_item_with_shortcut(shortcut_class:, shortcut_href: nil, **args)
        add_primary_menu_item(**args)
        add_shortcut(
          id: "#{args.fetch(:id)}-shortcut",
          title: args.fetch(:title),
          href: shortcut_href || args.fetch(:href),
          css_class: shortcut_class
        )
      end

      def add_view(name, props)
        @views[name] = props
      end

      def build
        menu = @menu_builder.build

        hide_menu_text = Feature.enabled?(:new_navbar_layout)

        menu.merge({
          views: @views,
          shortcuts: @shortcuts,
          menuTitle: (_('Menu') unless hide_menu_text),
          menuTooltip: (_('Main menu') if hide_menu_text)
        }.compact)
      end
    end
  end
end
