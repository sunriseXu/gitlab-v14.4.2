import Vue from 'vue';
import { queryToObject } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from './constants';

export const getQueryParams = (query) =>
  queryToObject(query, { gatherArrays: true, legacySpacesDecode: true });

export const keyValueToFilterToken = (type, data) => ({ type, value: { data } });

export const searchArrayToFilterTokens = (search) =>
  search.map((s) => keyValueToFilterToken(FILTERED_SEARCH_TERM, s));

export const extractFilterAndSorting = (queryObject) => {
  const { type, search, sort, orderBy } = queryObject;
  const filters = [];
  const sorting = {};

  if (type) {
    filters.push(keyValueToFilterToken('type', type));
  }
  if (search) {
    filters.push(...searchArrayToFilterTokens(search));
  }
  if (sort) {
    sorting.sort = sort;
  }
  if (orderBy) {
    sorting.orderBy = orderBy;
  }
  return { filters, sorting };
};

export const beautifyPath = (path) => (path ? path.split('/').join(' / ') : '');

export const getCommitLink = ({ project_path: projectPath, pipeline = {} }, isGroup = false) => {
  if (isGroup) {
    return `/${projectPath}/commit/${pipeline.sha}`;
  }

  return `../commit/${pipeline.sha}`;
};

export const renderBreadcrumb = (router, apolloProvider, RegistryBreadcrumb) => () => {
  const breadCrumbEls = document.querySelectorAll('nav .js-breadcrumbs-list li');
  const breadCrumbEl = breadCrumbEls[breadCrumbEls.length - 1];
  const lastCrumb = breadCrumbEl.children[0];
  const crumbs = [lastCrumb];
  const nestedBreadcrumbEl = document.createElement('div');
  breadCrumbEl.replaceChild(nestedBreadcrumbEl, lastCrumb);
  return new Vue({
    el: nestedBreadcrumbEl,
    router,
    apolloProvider,
    components: {
      RegistryBreadcrumb,
    },
    render(createElement) {
      // FIXME(@tnir): this is a workaround until the MR gets merged:
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48115
      const parentEl = breadCrumbEl.parentElement.parentElement;
      if (parentEl) {
        parentEl.classList.remove('breadcrumbs-container');
        parentEl.classList.add('gl-display-flex');
        parentEl.classList.add('w-100');
      }
      // End of FIXME(@tnir)
      return createElement('registry-breadcrumb', {
        class: breadCrumbEl.className,
        props: {
          crumbs,
        },
      });
    },
  });
};
