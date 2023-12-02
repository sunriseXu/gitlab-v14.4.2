import Vue, { nextTick } from 'vue';
import { GlToast, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory } from '~/lib/utils/url_utility';

import { upgradeStatusTokenConfig } from 'ee_else_ce/runner/components/search_tokens/upgrade_status_token_config';
import { createLocalState } from '~/runner/graphql/list/local_state';
import AdminRunnersApp from '~/runner/admin_runners/admin_runners_app.vue';
import RunnerStackedLayoutBanner from '~/runner/components/runner_stacked_layout_banner.vue';
import RunnerTypeTabs from '~/runner/components/runner_type_tabs.vue';
import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import RunnerBulkDelete from '~/runner/components/runner_bulk_delete.vue';
import RunnerBulkDeleteCheckbox from '~/runner/components/runner_bulk_delete_checkbox.vue';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerListEmptyState from '~/runner/components/runner_list_empty_state.vue';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerActionsCell from '~/runner/components/cells/runner_actions_cell.vue';
import RegistrationDropdown from '~/runner/components/registration/registration_dropdown.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';

import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  I18N_INSTANCE_TYPE,
  I18N_GROUP_TYPE,
  I18N_PROJECT_TYPE,
  INSTANCE_TYPE,
  PARAM_KEY_PAUSED,
  PARAM_KEY_STATUS,
  PARAM_KEY_TAG,
  STATUS_ONLINE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import allRunnersQuery from 'ee_else_ce/runner/graphql/list/all_runners.query.graphql';
import allRunnersCountQuery from 'ee_else_ce/runner/graphql/list/all_runners_count.query.graphql';
import { captureException } from '~/runner/sentry_utils';

import {
  allRunnersData,
  runnersCountData,
  allRunnersDataPaginated,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  emptyPageInfo,
  emptyStateSvgPath,
  emptyStateFilteredSvgPath,
} from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockRunners = allRunnersData.data.runners.nodes;
const mockRunnersCount = runnersCountData.data.runners.count;

const mockRunnersHandler = jest.fn();
const mockRunnersCountHandler = jest.fn();

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

Vue.use(VueApollo);
Vue.use(GlToast);

const COUNT_QUERIES = 7; // 4 tabs + 3 status queries

describe('AdminRunnersApp', () => {
  let wrapper;
  let cacheConfig;
  let localMutations;
  let showToast;

  const findRunnerStackedLayoutBanner = () => wrapper.findComponent(RunnerStackedLayoutBanner);
  const findRunnerStats = () => wrapper.findComponent(RunnerStats);
  const findRunnerActionsCell = () => wrapper.findComponent(RunnerActionsCell);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findRunnerTypeTabs = () => wrapper.findComponent(RunnerTypeTabs);
  const findRunnerBulkDelete = () => wrapper.findComponent(RunnerBulkDelete);
  const findRunnerBulkDeleteCheckbox = () => wrapper.findComponent(RunnerBulkDeleteCheckbox);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerListEmptyState = () => wrapper.findComponent(RunnerListEmptyState);
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationNext = () => findRunnerPagination().findByText(s__('Pagination|Next'));
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);

  const createComponent = ({
    props = {},
    mountFn = shallowMountExtended,
    provide,
    ...options
  } = {}) => {
    ({ cacheConfig, localMutations } = createLocalState());

    const handlers = [
      [allRunnersQuery, mockRunnersHandler],
      [allRunnersCountQuery, mockRunnersCountHandler],
    ];

    wrapper = mountFn(AdminRunnersApp, {
      apolloProvider: createMockApollo(handlers, {}, cacheConfig),
      propsData: {
        registrationToken: mockRegistrationToken,
        ...props,
      },
      provide: {
        localMutations,
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
        emptyStateSvgPath,
        emptyStateFilteredSvgPath,
        ...provide,
      },
      ...options,
    });

    showToast = jest.spyOn(wrapper.vm.$root.$toast, 'show');

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnersHandler.mockResolvedValue(allRunnersData);
    mockRunnersCountHandler.mockResolvedValue(runnersCountData);
  });

  afterEach(() => {
    mockRunnersHandler.mockReset();
    mockRunnersCountHandler.mockReset();
    showToast.mockReset();
    wrapper.destroy();
  });

  it('shows the feedback banner', () => {
    createComponent();
    expect(findRunnerStackedLayoutBanner().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    createComponent();

    expect(findRegistrationDropdown().props('registrationToken')).toBe(mockRegistrationToken);
    expect(findRegistrationDropdown().props('type')).toBe(INSTANCE_TYPE);
  });

  describe('shows total runner counts', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });
    });

    it('fetches counts', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);
    });

    it('shows the runner tabs', () => {
      const tabs = findRunnerTypeTabs().text();
      expect(tabs).toMatchInterpolatedText(
        `All ${mockRunnersCount} ${I18N_INSTANCE_TYPE} ${mockRunnersCount} ${I18N_GROUP_TYPE} ${mockRunnersCount} ${I18N_PROJECT_TYPE} ${mockRunnersCount}`,
      );
    });

    it('shows the total', () => {
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_ONLINE} ${mockRunnersCount}`);
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_OFFLINE} ${mockRunnersCount}`);
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_STALE} ${mockRunnersCount}`);
    });
  });

  it('shows the runners list', async () => {
    await createComponent();

    expect(mockRunnersHandler).toHaveBeenCalledTimes(1);
    expect(findRunnerList().props('runners')).toEqual(mockRunners);
  });

  it('runner item links to the runner admin page', async () => {
    await createComponent({ mountFn: mountExtended });

    const { id, shortSha } = mockRunners[0];
    const numericId = getIdFromGraphQLId(id);

    const runnerLink = wrapper.find('tr [data-testid="td-summary"]').find(GlLink);

    expect(runnerLink.text()).toBe(`#${numericId} (${shortSha})`);
    expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${numericId}`);
  });

  it('renders runner actions for each runner', async () => {
    await createComponent({ mountFn: mountExtended });

    const runnerActions = wrapper.find('tr [data-testid="td-actions"]').find(RunnerActionsCell);
    const runner = mockRunners[0];

    expect(runnerActions.props()).toEqual({
      runner,
      editUrl: runner.editAdminUrl,
    });
  });

  it('requests the runners with no filters', async () => {
    await createComponent();

    expect(mockRunnersHandler).toHaveBeenLastCalledWith({
      status: undefined,
      type: undefined,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('sets tokens in the filtered search', () => {
    createComponent();

    expect(findRunnerFilteredSearchBar().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_PAUSED,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        recentSuggestionsStorageKey: `${ADMIN_FILTERED_SEARCH_NAMESPACE}-recent-tags`,
      }),
      upgradeStatusTokenConfig,
    ]);
  });

  describe('Single runner row', () => {
    const { id: graphqlId, shortSha } = mockRunners[0];
    const id = getIdFromGraphQLId(graphqlId);

    beforeEach(async () => {
      mockRunnersCountHandler.mockClear();

      await createComponent({ mountFn: mountExtended });
    });

    it('Links to the runner page', async () => {
      const runnerLink = wrapper.find('tr [data-testid="td-summary"]').find(GlLink);

      expect(runnerLink.text()).toBe(`#${id} (${shortSha})`);
      expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${id}`);
    });

    it('When runner is paused or unpaused, some data is refetched', async () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);

      findRunnerActionsCell().vm.$emit('toggledPaused');

      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES * 2);
      expect(showToast).toHaveBeenCalledTimes(0);
    });

    it('When runner is deleted, data is refetched and a toast message is shown', async () => {
      findRunnerActionsCell().vm.$emit('deleted', { message: 'Runner deleted' });

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Runner deleted');
    });
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ONLINE}&runner_type[]=${INSTANCE_TYPE}&paused[]=true`);

      await createComponent({ mountFn: mountExtended });
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        runnerType: INSTANCE_TYPE,
        filters: [
          { type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } },
          { type: PARAM_KEY_PAUSED, value: { data: 'true', operator: '=' } },
        ],
        sort: 'CREATED_DESC',
        pagination: {},
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        status: STATUS_ONLINE,
        type: INSTANCE_TYPE,
        paused: true,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledWith({
        type: INSTANCE_TYPE,
        status: STATUS_ONLINE,
        paused: true,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });

      findRunnerFilteredSearchBar().vm.$emit('input', {
        runnerType: null,
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } }],
        sort: CREATED_ASC,
      });

      await nextTick();
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: expect.stringContaining('?status[]=ONLINE&sort=CREATED_ASC'),
      });
    });

    it('requests the runners with filters', () => {
      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        status: STATUS_ONLINE,
        sort: CREATED_ASC,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledWith({
        status: STATUS_ONLINE,
      });
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponent();
    expect(findRunnerList().props('loading')).toBe(true);
    expect(findRunnerPagination().attributes('disabled')).toBe('true');
  });

  describe('when bulk delete is enabled', () => {
    describe('Before runners are deleted', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          provide: {
            glFeatures: { adminRunnersBulkDelete: true },
          },
        });
      });

      it('runner bulk delete is available', () => {
        expect(findRunnerBulkDelete().props('runners')).toEqual(mockRunners);
      });

      it('runner bulk delete checkbox is available', () => {
        expect(findRunnerBulkDeleteCheckbox().props('runners')).toEqual(mockRunners);
      });

      it('runner list is checkable', () => {
        expect(findRunnerList().props('checkable')).toBe(true);
      });

      it('responds to checked items by updating the local cache', () => {
        const setRunnerCheckedMock = jest
          .spyOn(localMutations, 'setRunnerChecked')
          .mockImplementation(() => {});

        const runner = mockRunners[0];

        expect(setRunnerCheckedMock).toHaveBeenCalledTimes(0);

        findRunnerList().vm.$emit('checked', {
          runner,
          isChecked: true,
        });

        expect(setRunnerCheckedMock).toHaveBeenCalledTimes(1);
        expect(setRunnerCheckedMock).toHaveBeenCalledWith({
          runner,
          isChecked: true,
        });
      });
    });

    describe('When runners are deleted', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          provide: {
            glFeatures: { adminRunnersBulkDelete: true },
          },
        });
      });

      it('count data is refetched', async () => {
        expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);

        findRunnerBulkDelete().vm.$emit('deleted', { message: 'Runners deleted' });

        expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES * 2);
      });

      it('toast is shown', async () => {
        expect(showToast).toHaveBeenCalledTimes(0);

        findRunnerBulkDelete().vm.$emit('deleted', { message: 'Runners deleted' });

        expect(showToast).toHaveBeenCalledTimes(1);
        expect(showToast).toHaveBeenCalledWith('Runners deleted');
      });
    });
  });

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockRunnersHandler.mockResolvedValue({
        data: {
          runners: {
            nodes: [],
            pageInfo: emptyPageInfo,
          },
        },
      });

      await createComponent();
    });

    it('shows no errors', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows an empty state', () => {
      expect(findRunnerListEmptyState().props('isSearchFiltered')).toBe(false);
    });

    describe('when a filter is selected by the user', () => {
      beforeEach(async () => {
        findRunnerFilteredSearchBar().vm.$emit('input', {
          runnerType: null,
          filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } }],
          sort: CREATED_ASC,
        });
        await waitForPromises();
      });

      it('shows an empty state for a filtered search', () => {
        expect(findRunnerListEmptyState().props('isSearchFiltered')).toBe(true);
      });
    });
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockRunnersHandler.mockRejectedValue(new Error('Error!'));
      await createComponent();
    });

    it('error is shown to the user', async () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    const { pageInfo } = allRunnersDataPaginated.data.runners;

    beforeEach(async () => {
      mockRunnersHandler.mockResolvedValue(allRunnersDataPaginated);

      await createComponent({ mountFn: mountExtended });
    });

    it('passes the page info', () => {
      expect(findRunnerPagination().props('pageInfo')).toEqual(pageInfo);
    });

    it('navigates to the next page', async () => {
      await findRunnerPaginationNext().trigger('click');

      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: pageInfo.endCursor,
      });
    });
  });
});
