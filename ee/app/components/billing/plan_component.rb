# frozen_string_literal: true

module Billing
  class PlanComponent < ViewComponent::Base
    # @param [Namespace or Group] namespace
    # @param [Hashie::Mash] plan

    def initialize(plan:, namespace:)
      @plan = plan.merge(plans_data.fetch(plan.code, {}))
      @namespace = namespace
    end

    private

    attr_reader :plan, :namespace

    delegate :number_to_plan_currency, :plan_purchase_url, to: :helpers

    def render?
      # the data from customersDot may get out of sync, and this will make
      # sure this area isn't broken and also ensures local customersDot during
      # development only shows the plans we care about
      plans_data.key?(plan.code)
    end

    def free?
      plan.free
    end

    def card_classes
      "gl-mt-7 gl-mr-7 billing-plan-card #{plan.card_border_classes}"
    end

    def card_testid
      "plan-card-#{plan.code}"
    end

    def header_classes
      plan.header_classes
    end

    def header_text
      plan.header_text
    end

    def name
      plan.code.capitalize
    end

    def elevator_pitch
      plan.elevator_pitch
    end

    def price_per_month
      number_to_plan_currency(plan.price_per_month)
    end

    def annual_price_text
      s_("BillingPlans|Billed annually at %{price_per_year} USD") % { price_per_year: price_per_year }
    end

    def price_per_year
      number_to_plan_currency(plan.price_per_year)
    end

    def cta_text
      plan.cta_text
    end

    def cta_url
      if free?
        plan.purchase_link.href
      else
        plan_purchase_url(namespace, plan)
      end
    end

    def cta_classes
      "gl-mb-5 btn gl-button #{plan.cta_classes}"
    end

    def cta_data
      {
        track_action: 'click_button',
        track_label: 'plan_cta',
        track_property: plan.code,
        track_experiment: :promote_premium_billing_page
      }.merge(plan.cta_data)
    end

    def features
      plan.features
    end

    def plans_data
      {
        'free' => {
          "card_border_classes": "",
          "header_text": s_("BillingPlans|Your current plan"),
          "header_classes": "gl-line-height-normal gl-font-weight-bold gl-py-4 gl-h-8 gl-bg-gray-100",
          "elevator_pitch": s_("BillingPlans|Free forever features for individual users"),
          "features": [
            {
              "title": s_("BillingPlans|Spans the DevOps lifecycle")
            },
            {
              "title": s_("BillingPlans|Open Source - MIT License")
            },
            {
              "title": s_("BillingPlans|Includes free static websites")
            },
            {
              "title": s_("BillingPlans|5GB storage")
            },
            {
              "title": s_("BillingPlans|10GB transfer per month")
            },
            {
              "title": s_("BillingPlans|400 CI/CD minutes per month")
            },
            {
              "title": s_("BillingPlans|5 users per namespace")
            }
          ],
          "free": true,
          "cta_text": s_("BillingPlans|Learn more"),
          "cta_classes": " btn-confirm-secondary",
          "cta_data": {},
          "purchase_link": {
            "href": "https://about.gitlab.com/pricing/gitlab-com/feature-comparison/"
          }
        },
        'premium' => {
          "card_border_classes": "gl-border-purple-700",
          "header_text": s_("BillingPlans|Recommended"),
          "header_classes": "gl-line-height-normal gl-font-weight-bold gl-py-4 gl-h-8 gl-bg-purple-800 " \
                            "gl-text-white",
          "elevator_pitch": s_("BillingPlans|Enhance team productivity and collaboration"),
          "features": [
            {
              "title": s_("BillingPlans|All the features from Free")
            },
            {
              "title": s_("BillingPlans|Faster code reviews")
            },
            {
              "title": s_("BillingPlans|Advanced CI/CD")
            },
            {
              "title": s_("BillingPlans|Enterprise agile planning")
            },
            {
              "title": s_("BillingPlans|Release controls")
            },
            {
              "title": s_("BillingPlans|Self-managed reliability")
            },
            {
              "title": s_("BillingPlans|10,000 CI/CD minutes per month")
            },
            {
              "title": s_("BillingPlans|Support")
            }
          ],
          "free": false,
          "cta_text": s_("BillingPlans|Upgrade to Premium"),
          "cta_classes": "btn-purple",
          "cta_data": {
            "qa_selector": "upgrade_to_premium"
          }
        },
        'ultimate' => {
          "card_border_classes": "",
          "header_text": nil,
          "header_classes": "gl-bg-gray-100 gl-min-h-8",
          "elevator_pitch": s_("BillingPlans|Organization wide security, compliance and planning"),
          "features": [
            {
              "title": s_("BillingPlans|All the features from Premium")
            },
            {
              "title": s_("BillingPlans|Security risk mitigation")
            },
            {
              "title": s_("BillingPlans|Compliance")
            },
            {
              "title": s_("BillingPlans|Portfolio management")
            },
            {
              "title": s_("BillingPlans|Value stream management")
            },
            {
              "title": s_("BillingPlans|Free guest users")
            },
            {
              "title": s_("BillingPlans|50,000 CI/CD minutes per month")
            },
            {
              "title": s_("BillingPlans|Support")
            }
          ],
          "free": false,
          "cta_text": s_("BillingPlans|Upgrade to Ultimate"),
          "cta_classes": "btn-confirm-secondary",
          "cta_data": {
            "qa_selector": "upgrade_to_ultimate"
          }
        }
      }
    end
  end
end
