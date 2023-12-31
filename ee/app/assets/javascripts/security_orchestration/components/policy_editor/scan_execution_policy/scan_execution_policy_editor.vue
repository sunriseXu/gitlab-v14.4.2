<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { joinPaths, visitUrl, setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  EDITOR_MODES,
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  GRAPHQL_ERROR_MESSAGE,
  PARSING_ERROR_MESSAGE,
  SECURITY_POLICY_ACTIONS,
  ACTIONS_LABEL,
  ADD_ACTION_LABEL,
  ADD_RULE_LABEL,
  RULES_LABEL,
} from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import DimDisableContainer from '../dim_disable_container.vue';
import { assignSecurityPolicyProject, modifyPolicy } from '../utils';
import PolicyRuleBuilder from './policy_rule_builder.vue';
import PolicyActionBuilder from './policy_action_builder.vue';
import {
  buildScannerAction,
  buildDefaultPipeLineRule,
  DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml,
  toYaml,
} from './lib';
import { DEFAULT_SCANNER } from './constants';

export default {
  ACTION: 'actions',
  RULE: 'rules',
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  SECURITY_POLICY_ACTIONS,
  i18n: {
    ACTIONS_LABEL,
    ADD_ACTION_LABEL,
    ADD_RULE_LABEL,
    RULES_LABEL,
    PARSING_ERROR_MESSAGE,
    createMergeRequest: __('Configure with a merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan execution policies can only be created by project owners.',
    ),
  },
  components: {
    DimDisableContainer,
    GlButton,
    GlEmptyState,
    PolicyActionBuilder,
    PolicyEditorLayout,
    PolicyRuleBuilder,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'disableScanPolicyUpdate',
    'policyEditorEmptyStateSvgPath',
    'namespacePath',
    'scanPolicyDocumentationPath',
  ],
  props: {
    assignedPolicyProject: {
      type: Object,
      required: true,
    },
    existingPolicy: {
      type: Object,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const yamlEditorValue = this.existingPolicy
      ? toYaml(this.existingPolicy)
      : DEFAULT_SCAN_EXECUTION_POLICY;

    return {
      error: '',
      isCreatingMR: false,
      isRemovingPolicy: false,
      newlyCreatedPolicyProject: null,
      policy: fromYaml(yamlEditorValue),
      yamlEditorError: null,
      yamlEditorValue,
      mode: EDITOR_MODE_RULE,
      documentationPath: setUrlFragment(
        this.scanPolicyDocumentationPath,
        'scan-execution-policy-editor',
      ),
    };
  },
  computed: {
    originalName() {
      return this.existingPolicy?.name;
    },
    defaultEditorMode() {
      if (this.glFeatures.scanExecutionRuleMode) {
        return undefined;
      }
      return EDITOR_MODE_YAML;
    },
    editorModes() {
      if (this.glFeatures.scanExecutionRuleMode) {
        return undefined;
      }
      return [EDITOR_MODES[1]];
    },
    hasParsingError() {
      return Boolean(this.yamlEditorError);
    },
    policyYaml() {
      return this.hasParsingError ? '' : toYaml(this.policy);
    },
  },
  methods: {
    addAction() {
      this.policy.actions.push(buildScannerAction({ scanner: DEFAULT_SCANNER }));
    },
    addRule() {
      this.policy.rules.push(buildDefaultPipeLineRule());
    },
    removeActionOrRule(type, index) {
      this.policy[type].splice(index, 1);
    },
    updateActionOrRule(type, index, values) {
      this.policy[type].splice(index, 1, values);
    },
    changeEditorMode(mode) {
      this.mode = mode;
      if (mode === EDITOR_MODE_YAML && !this.hasParsingError) {
        this.yamlEditorValue = toYaml(this.policy);
      }
    },
    handleError(error) {
      if (error.message.toLowerCase().includes('graphql')) {
        this.$emit('error', GRAPHQL_ERROR_MESSAGE);
      } else {
        this.$emit('error', error.message);
      }
    },
    handleSetPolicyProperty(property, value) {
      this.policy[property] = value;
    },
    async getSecurityPolicyProject() {
      if (!this.newlyCreatedPolicyProject && !this.assignedPolicyProject.fullPath) {
        this.newlyCreatedPolicyProject = await assignSecurityPolicyProject(this.namespacePath);
      }

      return this.newlyCreatedPolicyProject || this.assignedPolicyProject;
    },
    async handleModifyPolicy(act) {
      const action =
        act ||
        (this.isEditing
          ? this.$options.SECURITY_POLICY_ACTIONS.REPLACE
          : this.$options.SECURITY_POLICY_ACTIONS.APPEND);

      this.$emit('error', '');
      this.setLoadingFlag(action, true);

      try {
        const assignedPolicyProject = await this.getSecurityPolicyProject();
        const yamlValue =
          this.mode === EDITOR_MODE_YAML ? this.yamlEditorValue : toYaml(this.policy);
        const mergeRequest = await modifyPolicy({
          action,
          assignedPolicyProject,
          name: this.originalName || fromYaml(this.yamlEditorValue)?.name || this.policy.name,
          namespacePath: this.namespacePath,
          yamlEditorValue: yamlValue,
        });

        this.redirectToMergeRequest({ mergeRequest, assignedPolicyProject });
      } catch (e) {
        this.handleError(e);
        this.setLoadingFlag(action, false);
      }
    },
    setLoadingFlag(action, val) {
      if (action === SECURITY_POLICY_ACTIONS.REMOVE) {
        this.isRemovingPolicy = val;
      } else {
        this.isCreatingMR = val;
      }
    },
    redirectToMergeRequest({ mergeRequest, assignedPolicyProject }) {
      visitUrl(
        joinPaths(
          gon.relative_url_root || '/',
          assignedPolicyProject.fullPath,
          '/-/merge_requests',
          mergeRequest.id,
        ),
      );
    },
    updateYaml(manifest) {
      this.yamlEditorValue = manifest;
      this.yamlEditorError = null;

      try {
        const newPolicy = fromYaml(manifest);
        if (newPolicy.error) {
          throw new Error(newPolicy.error);
        }
        this.policy = { ...this.policy, ...newPolicy };
      } catch (error) {
        this.yamlEditorError = error;
      }
    },
  },
};
</script>

<template>
  <policy-editor-layout
    v-if="!disableScanPolicyUpdate"
    :custom-save-button-text="$options.i18n.createMergeRequest"
    :default-editor-mode="defaultEditorMode"
    :editor-modes="editorModes"
    :has-parsing-error="hasParsingError"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isCreatingMR"
    :parsing-error="$options.i18n.PARSING_ERROR_MESSAGE"
    :policy="policy"
    :policy-yaml="policyYaml"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="handleModifyPolicy($options.SECURITY_POLICY_ACTIONS.REMOVE)"
    @save-policy="handleModifyPolicy()"
    @set-policy-property="handleSetPolicyProperty"
    @update-yaml="updateYaml"
    @update-editor-mode="changeEditorMode"
  >
    <template #rules>
      <dim-disable-container data-testid="rule-builder-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.RULES_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <policy-rule-builder
          v-for="(rule, index) in policy.rules"
          :key="index"
          class="gl-mb-4"
          :init-rule="rule"
          :rule-index="index"
          @changed="updateActionOrRule($options.RULE, index, $event)"
          @remove="removeActionOrRule($options.RULE, index)"
        />

        <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-mb-5">
          <gl-button variant="link" data-testid="add-rule" icon="plus" @click="addRule">
            {{ $options.i18n.ADD_RULE_LABEL }}
          </gl-button>
        </div>
      </dim-disable-container>
    </template>
    <template #actions>
      <dim-disable-container data-testid="action-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.ACTIONS_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <policy-action-builder
          v-for="(action, index) in policy.actions"
          :key="index"
          class="gl-mb-4"
          :init-action="action"
          :action-index="index"
          @changed="updateActionOrRule($options.ACTION, index, $event)"
          @remove="removeActionOrRule($options.ACTION, index)"
        />

        <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-mb-5">
          <gl-button variant="link" data-testid="add-action" icon="plus" @click="addAction">
            {{ $options.i18n.ADD_ACTION_LABEL }}
          </gl-button>
        </div>
      </dim-disable-container>
    </template>
  </policy-editor-layout>

  <gl-empty-state
    v-else
    :description="$options.i18n.notOwnerDescription"
    :primary-button-link="documentationPath"
    :primary-button-text="$options.i18n.notOwnerButtonText"
    :svg-path="policyEditorEmptyStateSvgPath"
    title=""
  />
</template>
