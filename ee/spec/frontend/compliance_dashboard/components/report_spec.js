import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlLink, GlKeysetPagination } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceReport from 'ee/compliance_dashboard/components/report.vue';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import MergeCommitsExportButton from 'ee/compliance_dashboard/components/shared/merge_commits_export_button.vue';
import ViolationReason from 'ee/compliance_dashboard/components/violations/reason.vue';
import ViolationFilter from 'ee/compliance_dashboard/components/violations/filter.vue';
import getComplianceViolationsQuery from 'ee/compliance_dashboard/graphql/compliance_violations.query.graphql';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { stripTypenames } from 'helpers/graphql_helpers';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { stubComponent } from 'helpers/stub_component';
import { sortObjectToString } from '~/lib/utils/table_utility';
import { parseViolationsQueryFilter } from 'ee/compliance_dashboard/utils';
import {
  DEFAULT_SORT,
  GRAPHQL_PAGE_SIZE,
  DEFAULT_PAGINATION_CURSORS,
} from 'ee/compliance_dashboard/constants';
import { createComplianceViolationsResponse } from '../mock_data';

Vue.use(VueApollo);

describe('ComplianceReport component', () => {
  let wrapper;

  const mergeCommitsCsvExportPath = '/csv';
  const groupPath = 'group-path';
  const mergedAfter = '2021-11-16';
  const mergedBefore = '2021-12-15';
  const defaultFilterParams = {
    projectIds: ['20'],
    mergedAfter,
    mergedBefore,
    sort: DEFAULT_SORT,
  };

  const violationsResponse = createComplianceViolationsResponse({ count: 2 });
  const violations = violationsResponse.data.group.mergeRequestViolations.nodes;
  const sentryError = new Error('GraphQL networkError');
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(violationsResponse);
  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);

  const findSubheading = () => wrapper.findByTestId('subheading');
  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findViolationsTable = () => wrapper.findComponent(GlTable);
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findMergeRequestDrawer = () => wrapper.findComponent(MergeRequestDrawer);
  const findMergeCommitsExportButton = () => wrapper.findComponent(MergeCommitsExportButton);
  const findViolationReason = () => wrapper.findComponent(ViolationReason);
  const findSeverityBadge = () => wrapper.findComponent(SeverityBadge);
  const findViolationFilter = () => wrapper.findComponent(ViolationFilter);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const findTableHeaders = () => findViolationsTable().findAll('th div');
  const findTableRowData = (idx) =>
    findViolationsTable().findAll('tbody > tr').at(idx).findAll('td');
  const findSelectedRows = () => findViolationsTable().findAll('tr.b-table-row-selected');

  const findRow = (idx) => {
    return findViolationsTable().findAll('tbody > tr').at(idx);
  };

  const selectRow = async (idx) => {
    await findRow(idx).trigger('click');
    await nextTick();
  };

  const viewDetails = async (idx) => {
    await findRow(idx).findComponent(GlButton).trigger('click');
    await nextTick();
  };

  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([[getComplianceViolationsQuery, resolverMock]]);
  };

  const createComponent = (
    mountFn = shallowMount,
    props = {},
    resolverMock = mockGraphQlLoading,
  ) => {
    return extendedWrapper(
      mountFn(ComplianceReport, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          mergeCommitsCsvExportPath,
          groupPath,
          defaultFilterParams,
          ...props,
        },
        stubs: {
          GlLink,
          GlTable: false,
          ViolationFilter: stubComponent(ViolationFilter),
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the subheading with a help link', () => {
      const helpLink = findSubheading().findComponent(GlLink);

      expect(findSubheading().text()).toContain(
        'The compliance report shows the merge request violations merged in protected environments.',
      );
      expect(helpLink.text()).toBe('Learn more.');
      expect(helpLink.attributes('href')).toBe('/help/user/compliance/compliance_report/index.md');
    });

    it('renders the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(true);
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('configures the filter', () => {
      expect(findViolationFilter().props()).toMatchObject({
        groupPath,
        defaultQuery: defaultFilterParams,
      });
    });
  });

  describe('when initializing', () => {
    beforeEach(() => {
      wrapper = createComponent(mount, {}, mockGraphQlLoading);
    });

    it('renders the table loading icon', () => {
      expect(findViolationsTable().exists()).toBe(true);
      expect(findTableLoadingIcon().exists()).toBe(true);
    });

    it('fetches the list of merge request violations with the default filter and sort params', async () => {
      expect(mockGraphQlLoading).toHaveBeenCalledTimes(1);
      expect(mockGraphQlLoading).toHaveBeenCalledWith({
        fullPath: groupPath,
        filters: parseViolationsQueryFilter(defaultFilterParams),
        sort: DEFAULT_SORT,
        ...DEFAULT_PAGINATION_CURSORS,
      });
    });
  });

  describe('when the defaultFilterParams has a sort param', () => {
    const sort = 'VIOLATION_ASC';

    beforeEach(() => {
      wrapper = createComponent(
        mount,
        { defaultFilterParams: { ...defaultFilterParams, sort } },
        mockGraphQlLoading,
      );
    });

    it('fetches the list of merge request violations with sort params', async () => {
      expect(mockGraphQlLoading).toHaveBeenCalledTimes(1);
      expect(mockGraphQlLoading).toHaveBeenCalledWith({
        fullPath: groupPath,
        filters: parseViolationsQueryFilter(defaultFilterParams),
        sort,
        ...DEFAULT_PAGINATION_CURSORS,
      });
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponent(shallowMount, {}, mockGraphQlError);
    });

    it('renders the error message', async () => {
      await waitForPromises();

      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe(
        'Retrieving the compliance report failed. Refresh the page and try again.',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('when there are violations', () => {
    beforeEach(() => {
      wrapper = createComponent(mount, {}, mockGraphQlSuccess);

      return waitForPromises();
    });

    it('does not render the table loading icon', () => {
      expect(mockGraphQlSuccess).toHaveBeenCalledTimes(1);

      expect(findTableLoadingIcon().exists()).toBe(false);
    });

    it('has the correct table headers', () => {
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual([
        'Severity',
        'Violation',
        'Merge request',
        'Date merged',
        '',
      ]);
    });

    it.each(Object.keys(violations))('has the correct data for row %s', (idx) => {
      const rowTexts = findTableRowData(idx).wrappers.map((d) => d.text());

      expect(rowTexts).toEqual([
        'High',
        'Approved by committer',
        violations[idx].mergeRequest.title,
        '2022-03-06',
        'View details',
      ]);
    });

    it('renders the violation severity badge', () => {
      const { severityLevel } = violations[0];

      expect(findSeverityBadge().props()).toStrictEqual({ severity: severityLevel });
    });

    it('renders the violation reason', () => {
      const { violatingUser, reason } = mapViolations(violations)[0];

      expect(findViolationReason().props()).toMatchObject({
        reason,
        user: violatingUser,
      });
    });

    describe('with the merge request drawer', () => {
      it('closes the drawer via the drawer close event', async () => {
        await selectRow(0);

        await findMergeRequestDrawer().vm.$emit('close');

        expect(findMergeRequestDrawer().props('showDrawer')).toBe(false);
        expect(findSelectedRows()).toHaveLength(0);
        expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual({});
        expect(findMergeRequestDrawer().props('project')).toStrictEqual({});
      });

      describe.each`
        rowAction      | eventDescription
        ${viewDetails} | ${'view details button is clicked'}
        ${selectRow}   | ${'row is selected'}
      `('when a $eventDescription', ({ rowAction, eventDescription }) => {
        it('opens then drawer', async () => {
          const drawerData = mapViolations(violations)[0];

          await rowAction(0);

          expect(findMergeRequestDrawer().props('showDrawer')).toBe(true);
          expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual(
            drawerData.mergeRequest,
          );
          expect(findMergeRequestDrawer().props('project')).toStrictEqual(
            drawerData.mergeRequest.project,
          );
        });

        it(`closes the drawer when the same ${eventDescription} again`, async () => {
          await rowAction(0);
          await rowAction(0);

          expect(findMergeRequestDrawer().props('showDrawer')).toBe(false);
          expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual({});
          expect(findMergeRequestDrawer().props('project')).toStrictEqual({});
        });

        it(`keeps the drawer open when another violation's ${eventDescription}`, async () => {
          const drawerData = mapViolations(violations)[1];

          await rowAction(0);
          await rowAction(1);

          expect(findMergeRequestDrawer().props('showDrawer')).toBe(true);
          expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual(
            drawerData.mergeRequest,
          );
          expect(findMergeRequestDrawer().props('project')).toStrictEqual(
            drawerData.mergeRequest.project,
          );
        });
      });
    });

    describe('when the filters changed', () => {
      const query = { mergedAfter, mergedBefore, projectIds: [1, 2, 3] };

      const changeFilters = async () => {
        wrapper = createComponent(mount, {}, mockGraphQlSuccess);

        await waitForPromises();

        return findViolationFilter().vm.$emit('filters-changed', query);
      };

      it('updates the URL query', async () => {
        await changeFilters();

        expect(findUrlSync().props('query')).toMatchObject(query);
      });

      it('shows the table loading icon', async () => {
        await changeFilters();

        expect(findTableLoadingIcon().exists()).toBe(true);
      });

      it('sets the pagination component to disabled', async () => {
        await changeFilters();

        expect(findPagination().props('disabled')).toBe(true);
      });

      it('clears the project URL query param if the project array is empty', async () => {
        await changeFilters();

        await findViolationFilter().vm.$emit('filters-changed', { ...query, projectIds: [] });

        expect(findUrlSync().props('query')).toMatchObject({ ...query, projectIds: null });
      });

      it('fetches the filtered violations', async () => {
        await changeFilters();

        expect(mockGraphQlSuccess).toHaveBeenCalledTimes(3);
        expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(3, {
          fullPath: groupPath,
          filters: parseViolationsQueryFilter(query),
          sort: DEFAULT_SORT,
          ...DEFAULT_PAGINATION_CURSORS,
        });
      });
    });

    describe('when the table sort changes', () => {
      const sortState = { sortBy: 'mergedAt', sortDesc: true };

      const changeTableSort = async () => {
        wrapper = createComponent(mount, {}, mockGraphQlSuccess);

        await waitForPromises();
        await findViolationsTable().vm.$emit('sort-changed', sortState);
      };

      it('updates the URL query', async () => {
        await changeTableSort();

        expect(findUrlSync().props('query')).toMatchObject({
          sort: sortObjectToString(sortState),
        });
      });

      it('shows the table loading icon', async () => {
        await changeTableSort();

        expect(findTableLoadingIcon().exists()).toBe(true);
      });

      it('fetches the sorted violations', async () => {
        await changeTableSort();

        expect(mockGraphQlSuccess).toHaveBeenCalledTimes(3);
        expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(3, {
          fullPath: groupPath,
          filters: parseViolationsQueryFilter(defaultFilterParams),
          sort: sortObjectToString(sortState),
          ...DEFAULT_PAGINATION_CURSORS,
        });
      });
    });

    describe('pagination', () => {
      it('renders and configures the pagination', () => {
        const pageInfo = stripTypenames(
          violationsResponse.data.group.mergeRequestViolations.pageInfo,
        );

        expect(findPagination().props()).toMatchObject({
          ...pageInfo,
          disabled: false,
        });
      });

      it.each`
        event     | after    | before   | first                | last
        ${'next'} | ${'foo'} | ${null}  | ${GRAPHQL_PAGE_SIZE} | ${undefined}
        ${'prev'} | ${null}  | ${'foo'} | ${undefined}         | ${GRAPHQL_PAGE_SIZE}
      `(
        'fetches the $event page when the pagination emits "$event"',
        async ({ event, after, before, first, last }) => {
          await findPagination().vm.$emit(event, after ?? before);
          await waitForPromises();

          expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
          expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(2, {
            fullPath: groupPath,
            filters: parseViolationsQueryFilter(defaultFilterParams),
            sort: DEFAULT_SORT,
            after,
            before,
            first,
            last,
          });
        },
      );

      describe('when there are no next or previous pages', () => {
        beforeEach(() => {
          const noPagesResponse = createComplianceViolationsResponse({
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
            },
          });
          const mockResolver = jest.fn().mockResolvedValue(noPagesResponse);

          wrapper = createComponent(mount, {}, mockResolver);

          return waitForPromises();
        });

        it('does not render the pagination component', () => {
          expect(findPagination().exists()).toBe(false);
        });
      });

      describe('when the next page has been selected', () => {
        beforeEach(() => {
          return findPagination().vm.$emit('next', 'foo');
        });

        it('clears the pagination when the filter is updated', async () => {
          const query = { projectIds: [1] };

          await findViolationFilter().vm.$emit('filters-changed', query);

          expect(mockGraphQlSuccess).toHaveBeenCalledTimes(3);
          expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(3, {
            fullPath: groupPath,
            filters: parseViolationsQueryFilter(query),
            sort: DEFAULT_SORT,
            ...DEFAULT_PAGINATION_CURSORS,
          });
        });
      });
    });
  });

  describe('when there are no violations', () => {
    beforeEach(() => {
      const noViolationsResponse = createComplianceViolationsResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(noViolationsResponse);

      wrapper = createComponent(mount, {}, mockResolver);

      return waitForPromises();
    });

    it('renders the empty table message', () => {
      expect(findViolationsTable().text()).toContain('No violations found');
    });
  });

  describe('when the merge commit export link is not present', () => {
    beforeEach(() => {
      wrapper = createComponent(shallowMount, { mergeCommitsCsvExportPath: '' });
    });

    it('does not render the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(false);
    });
  });
});
