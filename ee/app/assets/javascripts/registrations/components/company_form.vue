<script>
import {
  GlForm,
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormText,
  GlToggle,
} from '@gitlab/ui';
import {
  LEADS_COMPANY_NAME_LABEL,
  LEADS_COMPANY_SIZE_LABEL,
  LEADS_PHONE_NUMBER_LABEL,
  companySizes,
} from 'ee/vue_shared/leads/constants';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';
import CountryOrRegionSelector from 'ee/trials/components/country_or_region_selector.vue';
import {
  TRIAL_COMPANY_SIZE_PROMPT,
  TRIAL_PHONE_DESCRIPTION,
  TRIAL_FORM_SUBMIT_TEXT,
} from 'ee/trials/constants';
import { trackCompanyForm } from '~/google_tag_manager';

export default {
  csrf,
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormText,
    CountryOrRegionSelector,
    GlToggle,
  },
  inject: ['submitPath'],
  props: {
    trial: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      companyName: '',
      companySize: null,
      phoneNumber: null,
      country: '',
      state: '',
      websiteUrl: '',
      trialOnboardingFlow: this.trial,
    };
  },
  computed: {
    companySizeOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.companySizeSelectPrompt,
          id: null,
        },
        ...companySizes,
      ];
    },
    descriptionText() {
      return this.trial
        ? this.$options.i18n.description.trial
        : this.$options.i18n.description.registration;
    },
  },
  methods: {
    toggleTrial() {
      this.$emit('changed', {
        trialOnboardingFlow: this.trialOnboardingFlow,
      });
    },
    trackCompanyForm() {
      const aboutYourCompanyType = this.trialOnboardingFlow ? 'ultimate_trial' : 'free_account';
      trackCompanyForm(aboutYourCompanyType);
    },
  },
  i18n: {
    companyNameLabel: LEADS_COMPANY_NAME_LABEL,
    companySizeLabel: LEADS_COMPANY_SIZE_LABEL,
    companySizeSelectPrompt: TRIAL_COMPANY_SIZE_PROMPT,
    phoneNumberLabel: LEADS_PHONE_NUMBER_LABEL,
    phoneNumberDescription: TRIAL_PHONE_DESCRIPTION,
    formSubmitText: TRIAL_FORM_SUBMIT_TEXT,
    optional: __('(optional)'),
    websiteLabel: __('Website'),
    trialLabel: __('GitLab Ultimate trial'),
    trialToggleDescription: __(
      'Try all GitLab features for free for 30 days. No credit card required.',
    ),
    description: {
      trial: __('To activate your trial, we need additional details from you.'),
      registration: __('To complete registration, we need additional details from you.'),
    },
  },
};
</script>

<template>
  <gl-form :action="submitPath" method="post" @submit="trackCompanyForm">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-form-text class="gl-font-base gl-text-gray-400 gl-pb-3">{{ descriptionText }}</gl-form-text>
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-mt-5">
      <gl-form-group
        :label="$options.i18n.companyNameLabel"
        label-size="sm"
        label-for="company_name"
        class="gl-mr-5 gl-w-half gl-xs-w-full"
      >
        <gl-form-input
          id="company_name"
          :value="companyName"
          name="company_name"
          data-testid="company_name"
          required
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.companySizeLabel"
        label-size="sm"
        label-for="company_size"
        class="gl-w-half gl-xs-w-full company-size"
      >
        <gl-form-select
          id="company_size"
          :value="companySize"
          name="company_size"
          :options="companySizeOptionsWithDefault"
          value-field="id"
          text-field="name"
          data-testid="company_size"
          required
        />
      </gl-form-group>
    </div>
    <country-or-region-selector :country="country" :state="state" data-testid="country" required />
    <gl-form-group
      :label="$options.i18n.phoneNumberLabel"
      :optional-text="$options.i18n.optional"
      label-size="sm"
      :description="$options.i18n.phoneNumberDescription"
      label-for="phone_number"
      optional
    >
      <gl-form-input
        id="phone_number"
        :value="phoneNumber"
        name="phone_number"
        type="tel"
        data-testid="phone_number"
        pattern="^(\+)*[0-9-\s]+$"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.websiteLabel"
      :optional-text="$options.i18n.optional"
      label-size="sm"
      label-for="website_url"
      optional
    >
      <gl-form-input
        id="website_url"
        :value="websiteUrl"
        name="website_url"
        data-testid="website_url"
      />
    </gl-form-group>
    <gl-form-group
      v-show="!trial"
      :label="$options.i18n.trialLabel"
      label-size="sm"
      :optional-text="$options.i18n.optional"
      optional
    >
      <gl-form-text class="gl-pb-3">{{ $options.i18n.trialToggleDescription }}</gl-form-text>
      <gl-toggle
        v-model="trialOnboardingFlow"
        name="trial_onboarding_flow"
        :label="$options.i18n.trialLabel"
        label-position="hidden"
        data-testid="trial_onboarding_flow"
        @change="toggleTrial"
      />
    </gl-form-group>
    <gl-button type="submit" variant="confirm" class="gl-w-20">
      {{ $options.i18n.formSubmitText }}
    </gl-button>
  </gl-form>
</template>

<style>
.company-size {
  line-height: 1.2rem;
}
</style>
