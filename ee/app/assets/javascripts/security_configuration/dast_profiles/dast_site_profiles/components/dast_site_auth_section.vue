<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { initFormField } from 'ee/security_configuration/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import validation from '~/vue_shared/directives/validation';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
  },
  directives: {
    validation: validation(),
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    showValidation: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    stacked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isTargetApi: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const {
      enabled = false,
      url,
      username,
      password,
      // default to commonly used names for `username` and `password` fields in authentcation forms
      usernameField = 'username',
      passwordField = 'password',
      submitField,
    } = this.value.fields;

    return {
      form: {
        state: false,
        fields: {
          enabled: initFormField({ value: enabled, skipValidation: true }),
          url: initFormField({ value: url, required: false, skipValidation: true }),
          username: initFormField({ value: username }),
          password: this.isEditMode
            ? initFormField({ value: password, required: false, skipValidation: true })
            : initFormField({ value: password }),
          usernameField: initFormField({
            value: usernameField,
            required: false,
            skipValidation: true,
          }),
          passwordField: initFormField({
            value: passwordField,
            required: false,
            skipValidation: true,
          }),
          submitField: initFormField({ value: submitField, required: false, skipValidation: true }),
        },
      },
      isSensitiveFieldRequired: !this.isEditMode,
    };
  },
  computed: {
    showBasicAuthOption() {
      return this.isTargetApi;
    },
    i18n() {
      return {
        enableAuth: this.showBasicAuthOption
          ? s__('DastProfiles|Enable Basic Authentication')
          : s__('DastProfiles|Enable Authentication'),
      };
    },
  },
  watch: {
    form: { handler: 'emitUpdate', immediate: true, deep: true },
  },
  created() {
    this.emitUpdate();
  },
  methods: {
    emitUpdate() {
      this.$emit('input', {
        fields: serializeFormObject(this.form.fields),
        state: this.form.state,
      });
    },
  },
};
</script>

<template>
  <section>
    <gl-form-group data-testid="dast-site-auth-parent-group" :disabled="disabled">
      <gl-form-group :label="s__('DastProfiles|Authentication')">
        <gl-form-checkbox v-model="form.fields.enabled.value" data-testid="auth-enable-checkbox">{{
          i18n.enableAuth
        }}</gl-form-checkbox>
      </gl-form-group>
      <div v-if="form.fields.enabled.value" data-testid="auth-form">
        <div v-if="!showBasicAuthOption" class="row">
          <gl-form-group
            :label="s__('DastProfiles|Authentication URL')"
            :invalid-feedback="form.fields.url.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.url.value"
              v-validation:[showValidation]
              name="url"
              type="url"
              required
              :state="form.fields.url.state"
            />
          </gl-form-group>
        </div>
        <div class="row">
          <gl-form-group
            :label="s__('DastProfiles|Username')"
            :invalid-feedback="form.fields.username.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.username.value"
              v-validation:[showValidation]
              autocomplete="off"
              name="username"
              type="text"
              required
              :state="form.fields.username.state"
            />
          </gl-form-group>
          <gl-form-group
            :label="s__('DastProfiles|Password')"
            :invalid-feedback="form.fields.password.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.password.value"
              v-validation:[showValidation]
              autocomplete="off"
              name="password"
              type="password"
              :required="isSensitiveFieldRequired"
              :state="form.fields.password.state"
            />
          </gl-form-group>
        </div>
        <div v-if="!showBasicAuthOption" class="row">
          <gl-form-group
            :label="s__('DastProfiles|Username form field')"
            :invalid-feedback="form.fields.usernameField.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.usernameField.value"
              v-validation:[showValidation]
              name="usernameField"
              type="text"
              required
              :state="form.fields.usernameField.state"
            />
          </gl-form-group>
          <gl-form-group
            :label="s__('DastProfiles|Password form field')"
            :invalid-feedback="form.fields.passwordField.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.passwordField.value"
              v-validation:[showValidation]
              name="passwordField"
              type="text"
              required
              :state="form.fields.passwordField.state"
            />
          </gl-form-group>
        </div>
        <div v-if="!showBasicAuthOption" class="row">
          <gl-form-group
            :label="s__('DastProfiles|Submit button (optional)')"
            :invalid-feedback="form.fields.submitField.feedback"
            class="col-md-6"
            :class="{ 'col-md-12': stacked }"
          >
            <gl-form-input
              v-model="form.fields.submitField.value"
              v-validation:[showValidation]
              name="submitField"
              type="text"
              :state="form.fields.submitField.state"
            />
          </gl-form-group>
        </div>
      </div>
    </gl-form-group>
  </section>
</template>
