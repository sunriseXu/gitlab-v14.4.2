<script>
import { GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import autoMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/auto_merge';
import autoMergeEnabledQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/auto_merge_enabled.query.graphql';
import createFlash from '~/flash';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { AUTO_MERGE_STRATEGIES } from '../../constants';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import MrWidgetAuthor from '../mr_widget_author.vue';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetAutoMergeEnabled',
  apollo: {
    state: {
      query: autoMergeEnabledQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest,
    },
  },
  components: {
    MrWidgetAuthor,
    GlSkeletonLoader,
    GlSprintf,
    StateContainer,
  },
  mixins: [autoMergeMixin, glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: {},
      isCancellingAutoMerge: false,
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    loading() {
      return (
        this.glFeatures.mergeRequestWidgetGraphql &&
        this.$apollo.queries.state.loading &&
        Object.keys(this.state).length === 0
      );
    },
    mergeUser() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.mergeUser;
      }

      return this.mr.setToAutoMergeBy;
    },
    targetBranch() {
      return (this.glFeatures.mergeRequestWidgetGraphql ? this.state : this.mr).targetBranch;
    },
    shouldRemoveSourceBranch() {
      if (!this.glFeatures.mergeRequestWidgetGraphql) return this.mr.shouldRemoveSourceBranch;

      if (!this.state.shouldRemoveSourceBranch) return false;

      return this.state.shouldRemoveSourceBranch || this.state.forceRemoveSourceBranch;
    },
    autoMergeStrategy() {
      return (this.glFeatures.mergeRequestWidgetGraphql ? this.state : this.mr).autoMergeStrategy;
    },
    actions() {
      const actions = [];

      if (this.loading) {
        return actions;
      }

      if (this.mr.canCancelAutomaticMerge) {
        actions.push({
          text: this.cancelButtonText,
          loading: this.isCancellingAutoMerge,
          dataQaSelector: 'cancel_auto_merge_button',
          class: 'js-cancel-auto-merge',
          testId: 'cancelAutomaticMergeButton',
          onClick: () => this.cancelAutomaticMerge(),
        });
      }

      return actions;
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service
        .cancelAutomaticMerge()
        .then((res) => res.data)
        .then((data) => {
          if (this.glFeatures.mergeRequestWidgetGraphql) {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else {
            eventHub.$emit('UpdateWidgetData', data);
          }
        })
        .catch(() => {
          this.isCancellingAutoMerge = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        auto_merge_strategy: this.autoMergeStrategy,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service
        .merge(options)
        .then((res) => res.data)
        .then((data) => {
          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        })
        .then(() => {
          if (this.glFeatures.mergeRequestWidgetGraphql) {
            this.$apollo.queries.state.refetch();
          }
        })
        .catch(() => {
          this.isRemovingSourceBranch = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
  },
};
</script>
<template>
  <state-container :mr="mr" status="scheduled" :is-loading="loading" :actions="actions">
    <template #loading>
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="3" width="24" height="24" rx="4" />
        <rect x="32" y="7" width="150" height="16" rx="4" />
        <rect x="190" y="7" width="144" height="16" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-if="!loading">
      <h4 class="gl-mr-3" data-testid="statusText">
        <gl-sprintf :message="statusText" data-testid="statusText">
          <template #merge_author>
            <mr-widget-author :author="mergeUser" />
          </template>
        </gl-sprintf>
      </h4>
    </template>
  </state-container>
</template>
