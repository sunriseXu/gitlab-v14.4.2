import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { projectHelpPaths as helpLinks } from './constants';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-storage-counter-app');

  if (!el) {
    return false;
  }

  const {
    namespacePath,
    purchaseStorageUrl,
    buyAddonTargetAttr,
    isTemporaryStorageIncreaseVisible,
    defaultPerPage,
    storageLimitEnforced,
    additionalRepoStorageByNamespace,
    isFreeNamespace,
    isPersonalNamespace,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'NamespaceStorageApp',
    provide: {
      namespacePath,
      purchaseStorageUrl,
      buyAddonTargetAttr,
      isTemporaryStorageIncreaseVisible,
      helpLinks,
      defaultPerPage: Number(defaultPerPage),
    },
    render(createElement) {
      return createElement(NamespaceStorageApp, {
        props: {
          storageLimitEnforced: parseBoolean(storageLimitEnforced),
          isAdditionalStorageFlagEnabled: parseBoolean(additionalRepoStorageByNamespace),
          isFreeNamespace: parseBoolean(isFreeNamespace),
          isPersonalNamespace,
        },
      });
    },
  });
};
