# frozen_string_literal: true
module Pajamas
  class ButtonComponentPreview < ViewComponent::Preview
    # Button
    # ----
    # See its design reference [here](https://design.gitlab.com/components/banner).
    #
    # @param category select [primary, secondary, tertiary]
    # @param variant select [default, confirm, danger, dashed, link, reset]
    # @param size select [small, medium]
    # @param type select [button, reset, submit]
    # @param disabled toggle
    # @param loading toggle
    # @param block toggle
    # @param selected toggle
    # @param icon text
    # @param text text
    def default( # rubocop:disable Metrics/ParameterLists
      category: :primary,
      variant: :default,
      size: :medium,
      type: :button,
      disabled: false,
      loading: false,
      block: false,
      selected: false,
      icon: "pencil",
      text: "Edit"
    )
      render(Pajamas::ButtonComponent.new(
               category: category,
               variant: variant,
               size: size,
               type: type,
               disabled: disabled,
               loading: loading,
               block: block,
               selected: selected,
               icon: icon
             )) do
        text.presence
      end
    end

    # The component can also be used to create links that look and feel like buttons.
    # Just provide a `href` and optionally a `target` to create an `<a>` tag.
    def link
      render(Pajamas::ButtonComponent.new(
               href: "https://gitlab.com",
               target: "_blank"
             )) do
        "This is a link"
      end
    end
  end
end
