<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
  GlFormInput,
  GlSprintf,
  GlForm,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTION_THEN_LABEL, ACTION_AND_LABEL } from '../constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  DEFAULT_SCANNER,
  SCANNER_DAST,
  SCANNER_HUMANIZED_TEMPLATE,
  TEMPORARY_LIST_OF_SCANNERS,
} from './constants';
import { buildScannerAction } from './lib';

export default {
  SCANNERS: TEMPORARY_LIST_OF_SCANNERS,
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  props: {
    initAction: {
      type: Object,
      required: true,
    },
    actionIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      selectedScanner: this.initAction.scan || DEFAULT_SCANNER,
    };
  },
  computed: {
    actionLabel() {
      return this.actionIndex === 0 ? ACTION_THEN_LABEL : ACTION_AND_LABEL;
    },
    actionMessage() {
      return this.selectedScanner === SCANNER_DAST
        ? DAST_HUMANIZED_TEMPLATE
        : SCANNER_HUMANIZED_TEMPLATE;
    },
    siteProfile: {
      get() {
        return this.initAction.site_profile?.trim() ?? '';
      },
      set(value) {
        this.setSelectedScanner({ siteProfile: value });
      },
    },
    scannerProfile: {
      get() {
        return this.initAction.scanner_profile?.trim() ?? '';
      },
      set(value) {
        this.setSelectedScanner({ scannerProfile: value });
      },
    },
  },
  methods: {
    setSelectedScanner({
      scanner = this.selectedScanner,
      siteProfile = this.siteProfile,
      scannerProfile = this.scannerProfile,
    }) {
      if (scanner !== this.selectedScanner) {
        this.selectedScanner = scanner;
      }

      this.$emit('changed', buildScannerAction({ scanner, siteProfile, scannerProfile }));
    },
  },
  i18n: {
    selectedScannerProfilePlaceholder: s__('ScanExecutionPolicy|Select scanner profile'),
    selectedSiteProfilePlaceholder: s__('ScanExecutionPolicy|Select site profile'),
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-pl-5 gl-pr-7 gl-py-5 gl-relative">
    <gl-form inline class="gl-gap-3" @submit.prevent>
      <gl-sprintf :message="actionMessage">
        <template #thenLabel>
          <label class="text-uppercase gl-font-lg" data-testid="action-component-label">
            {{ actionLabel }}
          </label>
        </template>

        <template #scan>
          <gl-dropdown :text="$options.SCANNERS[selectedScanner]" data-testid="action-scanner-text">
            <gl-dropdown-item
              v-for="(value, key) in $options.SCANNERS"
              :key="key"
              @click="setSelectedScanner({ scanner: key })"
            >
              {{ value }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>

        <template #scannerProfile>
          <gl-form-group
            :label="s__('ScanExecutionPolicy|Scanner profile')"
            label-for="scanner-profile"
            label-sr-only
          >
            <gl-form-input
              id="scanner-profile"
              v-model="scannerProfile"
              :placeholder="$options.i18n.selectedScannerProfilePlaceholder"
              data-testid="scan-profile-selection"
            />
          </gl-form-group>
        </template>
        <template #siteProfile>
          <gl-form-group
            :label="s__('ScanExecutionPolicy|Site profile')"
            label-for="site-profile"
            label-sr-only
          >
            <gl-form-input
              id="site-profile"
              v-model="siteProfile"
              :placeholder="$options.i18n.selectedSiteProfilePlaceholder"
              data-testid="site-profile-selection"
            />
          </gl-form-group>
        </template>
      </gl-sprintf>
    </gl-form>
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      @click="$emit('remove', $event)"
    />
  </div>
</template>
