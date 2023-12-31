<script>
import { GlTooltip, GlIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

import { issuableTypesMap } from '~/related_issues/constants';
import EpicHealthStatus from './epic_health_status.vue';
import EpicActionsSplitButton from './epic_issue_actions_split_button.vue';

export default {
  components: {
    GlTooltip,
    GlIcon,
    EpicHealthStatus,
    EpicActionsSplitButton,
  },
  computed: {
    ...mapState([
      'parentItem',
      'weightSum',
      'descendantCounts',
      'healthStatus',
      'allowSubEpics',
      'allowIssuableHealthStatus',
    ]),
    totalEpicsCount() {
      return this.descendantCounts.openedEpics + this.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.descendantCounts.openedIssues + this.descendantCounts.closedIssues;
    },
    showHealthStatus() {
      return this.healthStatus && this.allowIssuableHealthStatus;
    },
    totalWeight() {
      return this.weightSum.openedIssues + this.weightSum.closedIssues;
    },
  },
  methods: {
    ...mapActions([
      'toggleCreateIssueForm',
      'toggleAddItemForm',
      'toggleCreateEpicForm',
      'setItemInputValue',
    ]),
    showAddIssueForm() {
      this.setItemInputValue('');
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.ISSUE,
        toggleState: true,
      });
    },
    showCreateIssueForm() {
      this.toggleCreateIssueForm({
        toggleState: true,
      });
    },
    showAddEpicForm() {
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.EPIC,
        toggleState: true,
      });
    },
    showCreateEpicForm() {
      this.toggleCreateEpicForm({
        toggleState: true,
      });
    },
  },
};
</script>

<template>
  <div
    class="card-header gl-display-flex gl-px-5 gl-py-3 gl-flex-direction-column gl-sm-flex-direction-row gl-bg-gray-10"
  >
    <div
      class="gl-display-flex gl-flex-grow-1 gl-flex-shrink-0 gl-flex-wrap gl-flex-direction-column gl-sm-flex-direction-row"
    >
      <div class="gl-display-flex gl-flex-shrink-0 gl-align-items-center gl-flex-wrap">
        <h3 class="card-title h5 gl-my-0 gl-flex-shrink-0">
          {{ allowSubEpics ? __('Child issues and epics') : __('Issues') }}
        </h3>
        <div class="gl-display-inline-flex lh-100 gl-vertical-align-middle gl-ml-5 gl-flex-wrap">
          <gl-tooltip :target="() => $refs.countBadge">
            <p v-if="allowSubEpics" class="gl-font-weight-bold gl-m-0">
              {{ __('Epics') }} &#8226;
              <span class="gl-font-weight-normal"
                >{{
                  sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                    openedEpics: descendantCounts.openedEpics,
                    closedEpics: descendantCounts.closedEpics,
                  })
                }}
              </span>
            </p>
            <p class="gl-font-weight-bold gl-m-0">
              {{ __('Issues') }} &#8226;
              <span class="gl-font-weight-normal"
                >{{
                  sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                    openedIssues: descendantCounts.openedIssues,
                    closedIssues: descendantCounts.closedIssues,
                  })
                }}
              </span>
            </p>
            <p class="gl-font-weight-bold gl-m-0">
              {{ __('Total weight') }} &#8226;
              <span class="gl-font-weight-normal">{{ totalWeight }} </span>
            </p>
          </gl-tooltip>
          <div
            ref="countBadge"
            class="issue-count-badge gl-display-inline-flex gl-text-secondary gl-p-0 gl-pr-5"
          >
            <span v-if="allowSubEpics" class="gl-display-inline-flex gl-align-items-center">
              <gl-icon name="epic" class="gl-mr-2" />
              {{ totalEpicsCount }}
            </span>
            <span
              class="gl-display-inline-flex gl-align-items-center"
              :class="{ 'gl-ml-3': allowSubEpics }"
            >
              <gl-icon name="issues" class="gl-mr-2" />
              {{ totalIssuesCount }}
            </span>
            <span
              class="gl-display-inline-flex gl-align-items-center"
              :class="{ 'gl-ml-3': allowSubEpics }"
            >
              <gl-icon name="weight" class="gl-mr-2" />
              {{ totalWeight }}
            </span>
          </div>
        </div>
      </div>
      <div
        class="gl-display-flex gl-sm-display-inline-flex lh-100 gl-vertical-align-middle gl-sm-ml-2 gl-ml-0 gl-flex-wrap gl-mt-2 gl-sm-mt-0"
      >
        <epic-health-status v-if="showHealthStatus" :health-status="healthStatus" />
      </div>
    </div>

    <div
      class="gl-display-flex gl-sm-display-inline-flex gl-sm-ml-auto lh-100 gl-vertical-align-middle gl-mt-3 gl-sm-mt-0 gl-pl-0 gl-sm-pl-7"
    >
      <div
        class="gl-flex-grow-1 gl-flex-direction-column gl-sm-flex-direction-row js-button-container"
      >
        <epic-actions-split-button
          :allow-sub-epics="allowSubEpics"
          class="js-add-epics-issues-button w-100"
          @showAddIssueForm="showAddIssueForm"
          @showCreateIssueForm="showCreateIssueForm"
          @showAddEpicForm="showAddEpicForm"
          @showCreateEpicForm="showCreateEpicForm"
        />
      </div>
    </div>
  </div>
</template>
