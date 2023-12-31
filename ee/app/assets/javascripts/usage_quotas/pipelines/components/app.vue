<script>
import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import getCiMinutesUsageProfile from 'ee/ci_minutes_usage/graphql/queries/ci_minutes.query.graphql';
import getCiMinutesUsageNamespace from '../../ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import getNamespaceProjectsInfo from '../queries/namespace_projects_info.query.graphql';
import { getProjectMinutesUsage } from '../utils';
import {
  ERROR_MESSAGE,
  LABEL_BUY_ADDITIONAL_MINUTES,
  TITLE_USAGE_SINCE,
  TITLE_CURRENT_PERIOD,
  TOTAL_USED_UNLIMITED,
  MINUTES_USED,
  ADDITIONAL_MINUTES,
  PERCENTAGE_USED,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
} from '../constants';
import ProjectList from './project_list.vue';
import UsageOverview from './usage_overview.vue';
import MinutesUsageCharts from './minutes_usage_charts.vue';

export default {
  name: 'PipelineUsageApp',
  components: { GlAlert, GlButton, GlLoadingIcon, ProjectList, UsageOverview, MinutesUsageCharts },
  inject: [
    'pageSize',
    'namespacePath',
    'namespaceId',
    'namespaceActualPlanName',
    'userNamespace',
    'ciMinutesAnyProjectEnabled',
    'ciMinutesDisplayMinutesAvailableData',
    'ciMinutesLastResetDate',
    'ciMinutesMonthlyMinutesLimit',
    'ciMinutesMonthlyMinutesUsed',
    'ciMinutesMonthlyMinutesUsedPercentage',
    'ciMinutesPurchasedMinutesLimit',
    'ciMinutesPurchasedMinutesUsed',
    'ciMinutesPurchasedMinutesUsedPercentage',
    'buyAdditionalMinutesPath',
    'buyAdditionalMinutesTarget',
  ],
  data() {
    return {
      error: '',
      namespace: null,
      ciMinutesUsages: [],
    };
  },
  apollo: {
    namespace: {
      query: getNamespaceProjectsInfo,
      variables() {
        return {
          fullPath: this.namespacePath,
          first: this.pageSize,
        };
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
    ciMinutesUsages: {
      query() {
        return this.userNamespace ? getCiMinutesUsageProfile : getCiMinutesUsageNamespace;
      },
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPE_GROUP, this.namespaceId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
  },
  computed: {
    projects() {
      return this.namespace?.projects?.nodes.map((project) => ({
        project,
        ci_minutes: getProjectMinutesUsage(project, this.ciMinutesUsages),
      }));
    },
    projectsPageInfo() {
      return this.namespace?.projects?.pageInfo ?? {};
    },
    shouldShowBuyAdditionalMinutes() {
      return this.buyAdditionalMinutesPath && this.buyAdditionalMinutesTarget;
    },
    isLoading() {
      return this.$apollo.queries.namespace.loading || this.$apollo.queries.ciMinutesUsages.loading;
    },
    monthlyUsageTitle() {
      if (this.ciMinutesLastResetDate) {
        return sprintf(TITLE_USAGE_SINCE, {
          usageSince: this.ciMinutesLastResetDate,
        });
      }

      return TITLE_CURRENT_PERIOD;
    },
    monthlyMinutesUsed() {
      return sprintf(MINUTES_USED, {
        minutesUsed: `${this.ciMinutesMonthlyMinutesUsed} / ${this.ciMinutesMonthlyMinutesLimit}`,
      });
    },
    purchasedMinutesUsed() {
      return sprintf(MINUTES_USED, {
        minutesUsed: `${this.ciMinutesPurchasedMinutesUsed} / ${this.ciMinutesPurchasedMinutesLimit}`,
      });
    },
    shouldShowAdditionalMinutes() {
      return (
        this.ciMinutesDisplayMinutesAvailableData && Number(this.ciMinutesPurchasedMinutesLimit) > 0
      );
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    fetchMoreProjects(variables) {
      this.$apollo.queries.namespace.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          ...variables,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    trackBuyAdditionalMinutesClick() {
      pushEECproductAddToCartEvent();
    },
    usagePercentage(percentage) {
      let percentageUsed;
      if (this.ciMinutesDisplayMinutesAvailableData) {
        percentageUsed = percentage;
      } else if (this.ciMinutesAnyProjectEnabled) {
        percentageUsed = 0;
      }

      if (percentageUsed) {
        return sprintf(PERCENTAGE_USED, {
          percentageUsed,
        });
      }

      return TOTAL_USED_UNLIMITED;
    },
  },
  LABEL_BUY_ADDITIONAL_MINUTES,
  ADDITIONAL_MINUTES,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-alert v-else-if="error" variant="danger" @dismiss="clearError">
      {{ error }}
    </gl-alert>
    <section v-else>
      <section>
        <div
          v-if="shouldShowBuyAdditionalMinutes"
          class="gl-display-flex gl-justify-content-end gl-py-3"
        >
          <gl-button
            :href="buyAdditionalMinutesPath"
            :target="buyAdditionalMinutesTarget"
            :data-track-label="namespaceActualPlanName"
            data-qa-selector="buy_ci_minutes"
            data-track-action="click_buy_ci_minutes"
            data-track-property="pipeline_quota_page"
            category="primary"
            variant="confirm"
            class="js-buy-additional-minutes"
            @click="trackBuyAdditionalMinutesClick"
          >
            {{ $options.LABEL_BUY_ADDITIONAL_MINUTES }}
          </gl-button>
        </div>
        <usage-overview
          :minutes-title="monthlyUsageTitle"
          :minutes-used="monthlyMinutesUsed"
          minutes-used-qa-selector="plan_ci_minutes"
          :minutes-used-percentage="usagePercentage(ciMinutesMonthlyMinutesUsedPercentage)"
          :minutes-limit="ciMinutesMonthlyMinutesLimit"
          :help-link-href="$options.CI_MINUTES_HELP_LINK"
          :help-link-label="$options.CI_MINUTES_HELP_LINK_LABEL"
          data-testid="monthly-usage-overview"
        />
        <usage-overview
          v-if="shouldShowAdditionalMinutes"
          class="gl-pt-5"
          :minutes-title="$options.ADDITIONAL_MINUTES"
          :minutes-used="purchasedMinutesUsed"
          minutes-used-qa-selector="additional_ci_minutes"
          :minutes-used-percentage="usagePercentage(ciMinutesPurchasedMinutesUsedPercentage)"
          :minutes-limit="ciMinutesPurchasedMinutesLimit"
          :help-link-href="$options.ADDITIONAL_MINUTES_HELP_LINK"
          :help-link-label="$options.ADDITIONAL_MINUTES"
          data-testid="purchased-usage-overview"
        />
      </section>
      <minutes-usage-charts :ci-minutes-usage="ciMinutesUsages" />
      <section class="gl-py-5">
        <project-list
          :projects="projects"
          :page-info="projectsPageInfo"
          @fetchMore="fetchMoreProjects"
        />
      </section>
    </section>
  </div>
</template>
