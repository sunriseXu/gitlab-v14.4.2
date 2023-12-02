# frozen_string_literal: true

module Gitlab
  # Module containing GitLab's application theme definitions and helper methods
  # for accessing them.
  module Themes
    extend self

    # Theme ID used when no `default_theme` configuration setting is provided.
    APPLICATION_DEFAULT = 1

    # Struct class representing a single Theme
    Theme = Struct.new(:id, :name, :css_class, :css_filename, :primary_color)

    # All available Themes
    def available_themes
      [
        Theme.new(1, s_('NavigationTheme|Indigo'), 'ui-indigo', 'theme_indigo', '#292961'),
        Theme.new(6, s_('NavigationTheme|Light Indigo'), 'ui-light-indigo', 'theme_light_indigo', '#4b4ba3'),
        Theme.new(4, s_('NavigationTheme|Blue'), 'ui-blue', 'theme_blue', '#1a3652'),
        Theme.new(7, s_('NavigationTheme|Light Blue'), 'ui-light-blue', 'theme_light_blue', '#2261a1'),
        Theme.new(5, s_('NavigationTheme|Green'), 'ui-green', 'theme_green', '#0d4524'),
        Theme.new(8, s_('NavigationTheme|Light Green'), 'ui-light-green', 'theme_light_green', '#156b39'),
        Theme.new(9, s_('NavigationTheme|Red'), 'ui-red', 'theme_red', '#691a16'),
        Theme.new(10, s_('NavigationTheme|Light Red'), 'ui-light-red', 'theme_light_red', '#a62e21'),
        Theme.new(2, s_('NavigationTheme|Gray'), 'ui-gray', 'theme_gray', '#303030'),
        Theme.new(3, s_('NavigationTheme|Light Gray'), 'ui-light-gray', 'theme_light_gray', '#666'),
        Theme.new(11, s_('NavigationTheme|Dark Mode (alpha)'), 'gl-dark', nil, '#303030')
      ]
    end

    # Convenience method to get a space-separated String of all the theme
    # classes that might be applied to the `body` element
    #
    # Returns a String
    def body_classes
      available_themes.collect(&:css_class).uniq.join(' ')
    end

    # Get a Theme by its ID
    #
    # If the ID is invalid, returns the default Theme.
    #
    # id - Integer ID
    #
    # Returns a Theme
    def by_id(id)
      available_themes.detect { |t| t.id == id } || default
    end

    # Returns the number of defined Themes
    def count
      available_themes.size
    end

    # Get the default Theme
    #
    # Returns a Theme
    def default
      by_id(default_id)
    end

    # Iterate through each Theme
    #
    # Yields the Theme object
    def each(&block)
      available_themes.each(&block)
    end

    # Get the Theme for the specified user, or the default
    #
    # user - User record
    #
    # Returns a Theme
    def for_user(user)
      if user
        by_id(user.theme_id)
      else
        default
      end
    end

    def self.valid_ids
      available_themes.map(&:id)
    end

    private

    def default_id
      @default_id ||= begin
        id = Gitlab.config.gitlab.default_theme.to_i
        theme_ids = available_themes.map(&:id)

        theme_ids.include?(id) ? id : APPLICATION_DEFAULT
      end
    end
  end
end
