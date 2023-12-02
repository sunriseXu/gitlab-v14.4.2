import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoNodeReplicationDetails from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_details.vue';
import GeoNodeReplicationDetailsResponsive from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_details_responsive.vue';
import GeoNodeReplicationStatusMobile from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_status_mobile.vue';
import { GEO_REPLICATION_SUPPORTED_TYPES_URL } from 'ee/geo_nodes/constants';
import { MOCK_SECONDARY_NODE, MOCK_REPLICABLE_TYPES } from 'ee_jest/geo_nodes/mock_data';

Vue.use(Vuex);

describe('GeoNodeReplicationDetails', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_SECONDARY_NODE,
  };

  const createComponent = (initialState, props, getters) => {
    const store = new Vuex.Store({
      state: {
        replicableTypes: MOCK_REPLICABLE_TYPES,
        ...initialState,
      },
      getters: {
        syncInfo: () => () => [],
        verificationInfo: () => () => [],
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoNodeReplicationDetails, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GeoNodeReplicationDetailsResponsive, GlSprintf },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoMobileReplicationDetails = () =>
    wrapper.findByTestId('geo-replication-details-mobile');
  const findGeoMobileReplicationStatus = () =>
    findGeoMobileReplicationDetails().findComponent(GeoNodeReplicationStatusMobile);
  const findGeoDesktopReplicationDetails = () =>
    wrapper.findByTestId('geo-replication-details-desktop');
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findNAVerificationHelpLink = () => wrapper.findByTestId('naVerificationHelpLink');
  const findReplicableComponent = () => wrapper.findByTestId('replicable-component');
  const findReplicableComponentLink = () => findReplicableComponent().findComponent(GlLink);

  describe('template', () => {
    describe('when un-collapsed', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the collapse button correctly', () => {
        expect(findCollapseButton().exists()).toBe(true);
        expect(findCollapseButton().attributes('icon')).toBe('chevron-down');
      });

      it('renders mobile replication details with correct visibility class', () => {
        expect(findGeoMobileReplicationDetails().exists()).toBe(true);
        expect(findGeoMobileReplicationDetails().classes()).toStrictEqual(['gl-md-display-none!']);
      });

      it('renders mobile replication details with mobile component slot', () => {
        expect(findGeoMobileReplicationStatus().exists()).toBe(true);
      });

      it('renders desktop details with correct visibility class', () => {
        expect(findGeoDesktopReplicationDetails().exists()).toBe(true);
        expect(findGeoDesktopReplicationDetails().classes()).toStrictEqual([
          'gl-display-none',
          'gl-md-display-block',
        ]);
      });

      it('renders Not applicable Verification Help Text with correct link', () => {
        expect(findNAVerificationHelpLink().attributes('href')).toBe(
          GEO_REPLICATION_SUPPORTED_TYPES_URL,
        );
      });
    });

    describe('when collapsed', () => {
      beforeEach(() => {
        createComponent();
        findCollapseButton().vm.$emit('click');
      });

      it('renders the collapse button correctly', () => {
        expect(findCollapseButton().exists()).toBe(true);
        expect(findCollapseButton().attributes('icon')).toBe('chevron-right');
      });

      it('does not render mobile replication details', () => {
        expect(findGeoMobileReplicationDetails().exists()).toBe(false);
      });

      it('does not render desktop replication details', () => {
        expect(findGeoDesktopReplicationDetails().exists()).toBe(false);
      });
    });

    const mockSync = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      title: MOCK_REPLICABLE_TYPES[0].titlePlural,
      values: { total: 100, success: 0 },
    };

    const mockVerif = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      title: MOCK_REPLICABLE_TYPES[0].titlePlural,
      values: { total: 50, success: 50 },
    };

    const mockExpectedNoValues = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_NODE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ),
      syncValues: null,
      verificationValues: null,
    };

    const mockExpectedOnlySync = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_NODE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ),
      syncValues: { total: 100, success: 0 },
      verificationValues: null,
    };

    const mockExpectedOnlyVerif = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_NODE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ),
      syncValues: null,
      verificationValues: { total: 50, success: 50 },
    };

    const mockExpectedBothTypes = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_NODE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ),
      syncValues: { total: 100, success: 0 },
      verificationValues: { total: 50, success: 50 },
    };

    describe.each`
      description                    | mockSyncData  | mockVerificationData | expectedProps              | hasNAVerificationHelpText
      ${'with no data'}              | ${[]}         | ${[]}                | ${[mockExpectedNoValues]}  | ${true}
      ${'with no verification data'} | ${[mockSync]} | ${[]}                | ${[mockExpectedOnlySync]}  | ${true}
      ${'with no sync data'}         | ${[]}         | ${[mockVerif]}       | ${[mockExpectedOnlyVerif]} | ${false}
      ${'with all data'}             | ${[mockSync]} | ${[mockVerif]}       | ${[mockExpectedBothTypes]} | ${false}
    `(
      '$description',
      ({ mockSyncData, mockVerificationData, expectedProps, hasNAVerificationHelpText }) => {
        beforeEach(() => {
          createComponent({ replicableTypes: [MOCK_REPLICABLE_TYPES[0]] }, null, {
            syncInfo: () => () => mockSyncData,
            verificationInfo: () => () => mockVerificationData,
          });
        });

        it('passes the correct props to the mobile replication details', () => {
          expect(findGeoMobileReplicationDetails().props()).toStrictEqual({
            replicationItems: expectedProps,
            nodeId: MOCK_SECONDARY_NODE.id,
          });
        });

        it('passes the correct props to the desktop replication details', () => {
          expect(findGeoDesktopReplicationDetails().props()).toStrictEqual({
            replicationItems: expectedProps,
            nodeId: MOCK_SECONDARY_NODE.id,
          });
        });

        it(`does ${
          hasNAVerificationHelpText ? '' : 'not '
        }show Not applicable verification help text`, () => {
          expect(findNAVerificationHelpLink().exists()).toBe(hasNAVerificationHelpText);
        });
      },
    );

    describe('component links', () => {
      describe('with noReplicationView', () => {
        beforeEach(() => {
          createComponent({ replicableTypes: [MOCK_REPLICABLE_TYPES[1]] });
        });

        it('renders replicable component title', () => {
          expect(findReplicableComponent().text()).toBe(MOCK_REPLICABLE_TYPES[1].titlePlural);
        });

        it(`does not render GlLink to secondary replication view`, () => {
          expect(findReplicableComponentLink().exists()).toBe(false);
        });
      });
    });

    describe.each`
      description                       | replicableType              | expectedUrl
      ${'with customReplicationUrl'}    | ${MOCK_REPLICABLE_TYPES[2]} | ${`${MOCK_SECONDARY_NODE.url}${MOCK_REPLICABLE_TYPES[2].customReplicationUrl}`}
      ${'without customReplicationUrl'} | ${MOCK_REPLICABLE_TYPES[3]} | ${`${MOCK_SECONDARY_NODE.url}admin/geo/sites/${MOCK_SECONDARY_NODE.id}/replication/${MOCK_REPLICABLE_TYPES[3].namePlural}`}
    `('component links $description', ({ replicableType, expectedUrl }) => {
      beforeEach(() => {
        createComponent({ replicableTypes: [replicableType] });
      });

      it('renders replicable component title', () => {
        expect(findReplicableComponent().text()).toBe(replicableType.titlePlural);
      });

      it(`renders GlLink to secondary replication view`, () => {
        expect(findReplicableComponentLink().exists()).toBe(true);
        expect(findReplicableComponentLink().attributes('href')).toBe(expectedUrl);
      });
    });
  });
});
