import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { merge, cloneDeep } from 'lodash';
import dastProfilesMock from 'test_fixtures/graphql/on_demand_scans/graphql/dast_profiles.query.graphql.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SavedTab from 'ee/on_demand_scans/components/tabs/saved.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import dastProfilesQuery from 'ee/on_demand_scans/graphql/dast_profiles.query.graphql';
import dastProfileRunMutation from 'ee/on_demand_scans/graphql/dast_profile_run.mutation.graphql';
import dastProfileDeleteMutation from 'ee/on_demand_scans/graphql/dast_profile_delete.mutation.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import {
  SAVED_TAB_TABLE_FIELDS,
  LEARN_MORE_TEXT,
  MAX_DAST_PROFILES_COUNT,
} from 'ee/on_demand_scans/constants';
import { s__ } from '~/locale';
import ScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import { PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK } from '../../mocks';

Vue.use(VueApollo);

// Mocks
jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/url_utility');
const [firstProfile] = dastProfilesMock.data.project.pipelines.nodes;
const GlTableMock = {
  firstProfile,
  template: `
    <div>
      <slot name="cell(actions)" :item="$options.firstProfile" />
      <slot name="error" />
    </div>`,
};
const errorAsDataMessage = 'Error-as-data message';

describe('Saved tab', () => {
  let wrapper;
  let router;
  let requestHandlers;

  // Props
  const projectPath = '/namespace/project';
  const itemsCount = 12;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);
  const findFirstRow = () => wrapper.find('tbody > tr');
  const findCellAt = (index) => findFirstRow().findAll('td').at(index);
  const findRunScanButton = () => wrapper.findByTestId('dast-scan-run-button');
  const findDeleteModal = () => wrapper.findComponent({ ref: 'delete-scan-modal' });

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([
      [dastProfilesQuery, requestHandlers.dastProfilesQuery],
      [dastProfileRunMutation, requestHandlers.dastProfileRunMutation],
      [dastProfileDeleteMutation, requestHandlers.dastProfileDeleteMutation],
    ]);
  };
  const makeDastProfileRunResponse = (errors = []) => ({
    data: {
      dastProfileRun: {
        pipelineUrl: '/pipelines/1',
        errors,
      },
    },
  });
  const makeDastProfileDeleteResponse = (errors = []) => ({
    data: {
      dastProfileDelete: {
        errors,
      },
    },
  });

  const createComponentFactory = (mountFn = shallowMountExtended) => (options = {}) => {
    router = createRouter();
    wrapper = mountFn(
      SavedTab,
      merge(
        {
          apolloProvider: createMockApolloProvider(),
          router,
          propsData: {
            isActive: true,
            itemsCount,
          },
          provide: {
            projectPath,
            projectOnDemandScanCountsEtag: PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK,
          },
          stubs: {
            BaseTab,
          },
        },
        options,
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mountExtended);

  beforeEach(() => {
    requestHandlers = {
      dastProfilesQuery: jest.fn().mockResolvedValue(dastProfilesMock),
      dastProfileRunMutation: jest.fn().mockResolvedValue(makeDastProfileRunResponse()),
      dastProfileDeleteMutation: jest.fn().mockResolvedValue(makeDastProfileDeleteResponse()),
    };
  });

  afterEach(() => {
    wrapper.destroy();
    router = null;
    requestHandlers = null;
  });

  it('renders the base tab with the correct props', () => {
    createComponent();

    expect(cloneDeep(findBaseTab().props())).toEqual({
      isActive: true,
      title: s__('OnDemandScans|Scan library'),
      itemsCount,
      maxItemsCount: MAX_DAST_PROFILES_COUNT,
      query: dastProfilesQuery,
      queryVariables: {},
      emptyStateTitle: s__('OnDemandScans|There are no saved scans.'),
      emptyStateText: LEARN_MORE_TEXT,
      fields: SAVED_TAB_TABLE_FIELDS,
    });
  });

  it('fetches the profiles', () => {
    createComponent();

    expect(requestHandlers.dastProfilesQuery).toHaveBeenCalledWith({
      after: null,
      before: null,
      first: 20,
      fullPath: projectPath,
      last: null,
    });
  });

  describe('custom table cells', () => {
    beforeEach(async () => {
      createFullComponent();
      await waitForPromises();
    });

    it('renders the branch name in the name cell', () => {
      const nameCell = findCellAt(0);

      expect(nameCell.text()).toContain(firstProfile.branch.name);
    });

    it('renders the scan type', () => {
      const firstScanTypeBadge = wrapper.findComponent(ScanTypeBadge);

      expect(firstScanTypeBadge.exists()).toBe(true);
      expect(firstScanTypeBadge.props('scanType')).toBe(firstProfile.dastScannerProfile.scanType);
    });
  });

  describe('edit button', () => {
    beforeEach(() => {
      createComponent({
        stubs: {
          GlTable: GlTableMock,
        },
      });
    });

    it.each(['desktop', 'mobile'])('renders the %s edit button', (layout) => {
      const editButton = wrapper.findByTestId(`edit-scan-button-${layout}`);

      expect(editButton.exists()).toBe(true);
      expect(editButton.attributes('href')).toBe(firstProfile.editPath);
    });
  });

  describe('run scan button', () => {
    describe('success', () => {
      beforeEach(async () => {
        createComponent({
          stubs: {
            GlTable: GlTableMock,
          },
        });
        await waitForPromises();
      });

      it('renders the button', () => {
        expect(findRunScanButton().exists()).toBe(true);
      });

      it('clicking on the button triggers the run scan mutation with the profile ID', () => {
        findRunScanButton().vm.$emit('click');

        expect(requestHandlers.dastProfileRunMutation).toHaveBeenCalledWith({
          input: { id: firstProfile.id },
        });
      });

      it('put the button in the loading and disabled state', async () => {
        const runScanButton = findRunScanButton();
        runScanButton.vm.$emit('click');
        await nextTick();

        expect(runScanButton.props('loading')).toBe(true);
        expect(runScanButton.props('disabled')).toBe(true);
      });

      it("redirects to the pipeline's page once the mutation resolves", async () => {
        findRunScanButton().vm.$emit('click');
        await waitForPromises();

        expect(redirectTo).toHaveBeenCalledWith('/pipelines/1');
      });
    });

    const topLevelErrorMessage = s__('OnDemandScans|Could not run the scan. Please try again.');

    describe.each`
      errorType            | errorMessage            | requestHander
      ${'error-as-data'}   | ${errorAsDataMessage}   | ${jest.fn().mockResolvedValue(makeDastProfileRunResponse([errorAsDataMessage]))}
      ${'top-level error'} | ${topLevelErrorMessage} | ${jest.fn().mockRejectedValue()}
    `('when deletion fails with $errorType', ({ errorMessage, requestHander }) => {
      beforeEach(async () => {
        requestHandlers.dastProfileRunMutation = requestHander;
        createComponent({
          stubs: {
            GlTable: GlTableMock,
          },
        });
        findRunScanButton().vm.$emit('click');
        await waitForPromises();
      });

      it('shows the error message', () => {
        expect(wrapper.text()).toContain(errorMessage);
      });

      it('hides the error message when retrying the deletion', async () => {
        findRunScanButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.text()).not.toContain(errorMessage);
      });

      it("resets the button's state", async () => {
        const runScanButton = findRunScanButton();

        expect(runScanButton.props('loading')).toBe(false);
        expect(runScanButton.props('disabled')).toBe(false);
      });
    });
  });

  describe('delete button', () => {
    describe.each(['desktop', 'mobile'])('%s layout', (layout) => {
      let deleteButton;

      beforeEach(() => {
        createComponent({
          stubs: {
            GlTable: GlTableMock,
            GlModal: {
              template: '<div />',
              methods: {
                show: () => {},
              },
            },
          },
        });

        deleteButton = wrapper.findByTestId(`delete-scan-button-${layout}`);
      });

      afterEach(() => {
        deleteButton = null;
      });

      it('renders the button', () => {
        expect(deleteButton.exists()).toBe(true);
      });

      it('clicking on the button opens the delete modal', () => {
        jest.spyOn(wrapper.vm.$refs['delete-scan-modal'], 'show');
        deleteButton.vm.$emit('click');

        expect(wrapper.vm.$refs['delete-scan-modal'].show).toHaveBeenCalled();
      });

      it('confirming the deletion in the modal triggers the delete mutation with the profile ID', async () => {
        deleteButton.vm.$emit('click');
        findDeleteModal().vm.$emit('ok');

        expect(requestHandlers.dastProfileDeleteMutation).toHaveBeenCalledWith({
          input: { id: firstProfile.id },
        });
      });
    });

    const topLevelErrorMessage = s__(
      'OnDemandScans|Could not delete saved scan. Please refresh the page, or try again later.',
    );

    describe.each`
      errorType            | errorMessage            | requestHander
      ${'error-as-data'}   | ${errorAsDataMessage}   | ${jest.fn().mockResolvedValue(makeDastProfileDeleteResponse([errorAsDataMessage]))}
      ${'top-level error'} | ${topLevelErrorMessage} | ${jest.fn().mockRejectedValue()}
    `('when deletion fails with $errorType', ({ errorMessage, requestHander }) => {
      beforeEach(async () => {
        requestHandlers.dastProfileDeleteMutation = requestHander;
        createComponent({
          stubs: {
            GlTable: GlTableMock,
          },
        });
        await waitForPromises();
        findDeleteModal().vm.$emit('ok');
        await waitForPromises();
      });

      it('shows the error message', () => {
        expect(wrapper.text()).toContain(errorMessage);
      });

      it('hides the error message when retrying the deletion', async () => {
        findDeleteModal().vm.$emit('ok');
        await nextTick();

        expect(wrapper.text()).not.toContain(errorMessage);
      });
    });
  });
});
