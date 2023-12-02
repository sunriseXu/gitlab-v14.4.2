# frozen_string_literal: true

module AppearancesHelper
  include MarkupHelper
  include Gitlab::Utils::StrongMemoize

  def brand_title
    current_appearance&.title.presence || default_brand_title
  end

  def default_brand_title
    # This resides in a separate method so that EE can easily redefine it.
    'GitLab Community Edition'
  end

  def brand_image
    image_tag(current_appearance.logo_path) if current_appearance&.logo?
  end

  def brand_text
    markdown_field(current_appearance, :description)
  end

  def brand_new_project_guidelines
    markdown_field(current_appearance, :new_project_guidelines)
  end

  def brand_profile_image_guidelines
    markdown_field(current_appearance, :profile_image_guidelines)
  end

  def current_appearance
    strong_memoize(:current_appearance) do
      Appearance.current
    end
  end

  def brand_header_logo(options = {})
    add_gitlab_white_text = options[:add_gitlab_white_text] || false
    add_gitlab_black_text = options[:add_gitlab_black_text] || false

    if current_appearance&.header_logo?
      image_tag current_appearance.header_logo_path, class: 'brand-header-logo'
    elsif add_gitlab_white_text
      render partial: 'shared/logo_with_white_text', formats: :svg
    elsif add_gitlab_black_text
      render partial: 'shared/logo_with_black_text', formats: :svg
    else
      render partial: 'shared/logo', formats: :svg
    end
  end

  def header_message
    return unless current_appearance&.show_header?

    class_names = []
    class_names << 'with-performance-bar' if performance_bar_enabled?

    render_message(:header_message, class_names: class_names)
  end

  def footer_message
    return unless current_appearance&.show_footer?

    render_message(:footer_message)
  end

  private

  def render_message(field_sym, class_names: [], style: message_style)
    class_names << field_sym.to_s.dasherize

    content_tag :div, class: class_names, style: style do
      markdown_field(current_appearance, field_sym)
    end
  end

  def message_style
    style = []
    style << "background-color: #{current_appearance.message_background_color};"
    style << "color: #{current_appearance.message_font_color}"
    style.join
  end
end

AppearancesHelper.prepend_mod
