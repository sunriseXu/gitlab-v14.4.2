<script>
import RunnerSingleStat from '~/runner/components/stat/runner_single_stat.vue';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
} from '../../constants';

export default {
  components: {
    RunnerSingleStat,
    RunnerUpgradeStatusStats: () =>
      import('ee_component/runner/components/stat/runner_upgrade_status_stats.vue'),
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    stats() {
      return [
        {
          key: STATUS_ONLINE,
          props: {
            skip: this.statusCountSkip(STATUS_ONLINE),
            variables: { ...this.variables, status: STATUS_ONLINE },
            variant: 'success',
            title: I18N_STATUS_ONLINE,
            metaIcon: 'status-active',
          },
        },
        {
          key: STATUS_OFFLINE,
          props: {
            skip: this.statusCountSkip(STATUS_OFFLINE),
            variables: { ...this.variables, status: STATUS_OFFLINE },
            variant: 'muted',
            title: I18N_STATUS_OFFLINE,
            metaIcon: 'status-waiting',
          },
        },
        {
          key: STATUS_STALE,
          props: {
            skip: this.statusCountSkip(STATUS_STALE),
            variables: { ...this.variables, status: STATUS_STALE },
            variant: 'warning',
            title: I18N_STATUS_STALE,
            metaIcon: 'time-out',
          },
        },
      ];
    },
  },
  methods: {
    statusCountSkip(status) {
      // Show an empty result when we already filter by another status
      return this.variables.status && this.variables.status !== status;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap gl-py-6">
    <runner-single-stat
      v-for="stat in stats"
      :key="stat.key"
      :scope="scope"
      v-bind="stat.props"
      class="gl-px-5"
    />

    <runner-upgrade-status-stats
      class="gl-display-contents"
      :scope="scope"
      :variables="variables"
    />
  </div>
</template>
