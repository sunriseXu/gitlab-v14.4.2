import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import SubscriptionSeats from './components/subscription_seats.vue';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-seat-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const {
    namespaceId,
    namespaceName,
    seatUsageExportPath,
    pendingMembersPagePath,
    pendingMembersCount,
    addSeatsHref,
    hasNoSubscription,
    maxFreeNamespaceSeats,
    explorePlansPath,
    freeUserCapEnabled,
    previewFreeUserCap,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: {},
    name: 'SeatsUsageApp',
    store: new Vuex.Store(
      initialStore({
        namespaceId,
        namespaceName,
        seatUsageExportPath,
        pendingMembersPagePath,
        pendingMembersCount,
        addSeatsHref,
        hasNoSubscription: parseBoolean(hasNoSubscription),
        maxFreeNamespaceSeats: parseInt(maxFreeNamespaceSeats, 10),
        explorePlansPath,
        freeUserCapEnabled: parseBoolean(freeUserCapEnabled),
        previewFreeUserCap: parseBoolean(previewFreeUserCap),
      }),
    ),
    render(createElement) {
      return createElement(SubscriptionSeats);
    },
  });
};
