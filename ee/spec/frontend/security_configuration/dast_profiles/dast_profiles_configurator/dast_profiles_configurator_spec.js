import { merge } from 'lodash';
import { GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import { s__ } from '~/locale';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import SiteProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import DastProfilesSidebar from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar.vue';
import DastProfilesSidebarList from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar_list.vue';
import DastProfilesSidebarForm from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar_form.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import resolvers from 'ee/vue_shared/security_configuration/graphql/resolvers/resolvers';
import { typePolicies } from 'ee/vue_shared/security_configuration/graphql/provider';
import waitForPromises from 'helpers/wait_for_promises';
import createApolloProvider from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  siteProfiles,
  scannerProfiles,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastProfilesConfigurator', () => {
  let localVue;
  let wrapper;
  let requestHandlers;
  const projectPath = 'projectPath';

  const createMockApolloProvider = () => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(scannerProfilesFixtures),
      dastSiteProfiles: jest.fn().mockResolvedValue(siteProfilesFixtures),
    };

    return createApolloProvider(
      [
        [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
        [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
      ],
      resolvers,
      { typePolicies },
    );
  };

  const findModal = () => wrapper.findByTestId('dast-profile-form-cancel-modal');
  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findEditBtn = () => wrapper.findByTestId('profile-edit-btn');
  const findNewScanButton = () => wrapper.findByTestId('new-profile-button');
  const findOpenDrawerButton = () => wrapper.findByTestId('select-profile-action-btn');
  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findInUseLabel = () => wrapper.findByTestId('in-use-label');
  const findSectionLayout = () => wrapper.findComponent(SectionLayout);
  const findSectionLoader = () => wrapper.findComponent(SectionLoader);
  const findScannerProfilesSelector = () => wrapper.findComponent(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.findComponent(SiteProfileSelector);
  const findAllScannerProfileSummary = () => wrapper.findAllComponents(ScannerProfileSummary);
  const findAllSiteProfileSummary = () => wrapper.findAllComponents(SiteProfileSummary);
  const findDastProfileSidebar = () => wrapper.findComponent(DastProfilesSidebar);
  const findDastProfilesSidebarList = () => wrapper.findComponent(DastProfilesSidebarList);
  const findDastProfilesSidebarForm = () => wrapper.findComponent(DastProfilesSidebarForm);

  const openDrawer = async () => {
    findOpenDrawerButton().vm.$emit('click');
    await waitForPromises();
  };

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    localVue = createLocalVue();

    const apolloProvider = createMockApolloProvider();

    wrapper = extendedWrapper(
      mountFn(
        DastProfilesConfigurator,
        merge(
          {},
          {
            propsData: {
              ...options,
            },
            stubs: {
              SectionLayout,
              ScannerProfileSelector,
              SiteProfileSelector,
              GlModal: true,
            },
            provide: {
              projectPath,
            },
          },
          { ...options, localVue, apolloProvider },
          {
            data() {
              return {
                scannerProfiles,
                siteProfiles,
                ...options.data,
              };
            },
          },
        ),
      ),
    );
    return wrapper;
  };
  const createComponent = createComponentFactory(mount);
  const createShallowComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when default state', () => {
    it('renders properly', async () => {
      const sectionHeader = s__('OnDemandScans|DAST configuration');
      createComponent({ configurationHeader: sectionHeader });
      await waitForPromises();

      expect(findSectionLayout().find('h2').text()).toContain(sectionHeader);
      expect(findScannerProfilesSelector().exists()).toBe(true);
      expect(findSiteProfilesSelector().exists()).toBe(true);
    });

    it('renders a link to the docs', () => {
      createComponent();
      const link = findSectionLayout().findComponent(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it('shows loader in loading state', () => {
      createShallowComponent();

      expect(findSectionLoader().exists()).toBe(true);
    });
  });

  describe('profile drawer', () => {
    beforeEach(async () => {
      createComponent({}, true);
      await waitForPromises();
    });

    it('should open drawer with scanner profiles', async () => {
      findScannerProfilesSelector().vm.$emit('open-drawer');
      await waitForPromises();

      expect(findDastProfileSidebar().exists()).toBe(true);
      expect(findAllScannerProfileSummary()).toHaveLength(scannerProfiles.length);
    });

    it('should open drawer with site profiles', async () => {
      findSiteProfilesSelector().vm.$emit('open-drawer');
      await waitForPromises();

      expect(findDastProfileSidebar().exists()).toBe(true);
      expect(findAllSiteProfileSummary()).toHaveLength(siteProfiles.length);
    });
  });

  describe('saved profiles', () => {
    const savedProfiles = {
      dastScannerProfile: { id: scannerProfiles[0].id },
      dastSiteProfile: { id: siteProfiles[0].id },
    };

    it('should have profiles selected if saved profiles exist', async () => {
      createComponent({ savedProfiles });
      await waitForPromises();

      expect(findScannerProfilesSelector().find('h3').text()).toContain(
        scannerProfiles[0].profileName,
      );
      expect(findSiteProfilesSelector().find('h3').text()).toContain(siteProfiles[0].profileName);
    });
  });

  describe('saved profile names', () => {
    const { profileName: savedScannerProfileName } = scannerProfiles[0];
    const { profileName: savedSiteProfileName } = siteProfiles[0];

    beforeEach(async () => {
      createComponent({ savedSiteProfileName, savedScannerProfileName }, true);
      await waitForPromises();
    });

    it('should have saved profiles selected', async () => {
      expect(findScannerProfilesSelector().find('h3').text()).toContain(savedScannerProfileName);
      expect(findSiteProfilesSelector().find('h3').text()).toContain(savedSiteProfileName);
    });

    it('should mark saved profiles as in-use', async () => {
      await openDrawer();
      expect(findInUseLabel().exists()).toBe(true);
    });
  });

  describe('switching between modes', () => {
    beforeEach(async () => {
      createComponent({}, true);
      await waitForPromises();
    });

    const expectEditingMode = async () => {
      findNewScanButton().vm.$emit('click');
      await waitForPromises();
      expect(findDastProfilesSidebarForm().exists()).toBe(true);
    };

    it('should have reading mode by default', async () => {
      await openDrawer();

      expect(findDastProfilesSidebarList().exists()).toBe(true);
    });

    it('should have editing mode by default', async () => {
      await openDrawer();
      await expectEditingMode();
    });

    it('should return from editing mode to reading mode', async () => {
      await openDrawer();
      await expectEditingMode();

      findCancelButton().vm.$emit('click');
      await waitForPromises();

      expect(findDastProfilesSidebarList().exists()).toBe(true);
    });
  });

  describe('warning modal', () => {
    beforeEach(async () => {
      createComponent({}, true);
      await waitForPromises();
    });

    it('should show warning modal when changes are unsaved', async () => {
      const mutateMock = jest.spyOn(wrapper.vm.$apollo, 'mutate');

      findOpenDrawerButton().vm.$emit('click');
      await waitForPromises();

      findEditBtn().vm.$emit('click');
      await waitForPromises();

      findProfileNameInput().vm.$emit('input', 'another value');
      await waitForPromises();

      findOpenDrawerButton().vm.$emit('click');
      await waitForPromises();

      expect(findModal().attributes('visible')).toEqual(String(true));
      expect(mutateMock).toHaveBeenCalledTimes(3);
    });
  });
});
