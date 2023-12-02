import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from '~/packages_and_registries/package_registry/graphql/index';
import PackageRegistry from '~/packages_and_registries/package_registry/pages/index.vue';
import RegistryBreadcrumb from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';
import { renderBreadcrumb } from '~/packages_and_registries/shared/utils';
import createRouter from './router';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');
  const {
    endpoint,
    resourceId,
    fullPath,
    pageType,
    emptyListIllustration,
    npmInstanceUrl,
    projectListUrl,
    groupListUrl,
  } = el.dataset;

  const isGroupPage = pageType === 'groups';

  // This is a mini state to help the breadcrumb have the correct name in the details page
  const breadCrumbState = Vue.observable({
    name: '',
    updateName(value) {
      this.name = value;
    },
  });

  const router = createRouter(endpoint, breadCrumbState);

  const attachMainComponent = () =>
    new Vue({
      el,
      router,
      apolloProvider,
      provide: {
        resourceId,
        fullPath,
        emptyListIllustration,
        isGroupPage,
        npmInstanceUrl,
        projectListUrl,
        groupListUrl,
        breadCrumbState,
      },
      render(createElement) {
        return createElement(PackageRegistry);
      },
    });

  return {
    attachBreadcrumb: renderBreadcrumb(router, apolloProvider, RegistryBreadcrumb),
    attachMainComponent,
  };
};
