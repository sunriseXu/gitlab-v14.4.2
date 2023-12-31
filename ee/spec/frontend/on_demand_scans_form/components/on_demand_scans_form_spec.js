import { GlForm, GlFormInput, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import OnDemandScansForm from 'ee/on_demand_scans_form/components/on_demand_scans_form.vue';
import ScannerProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/site_profile_selector.vue';
import ScanSchedule from 'ee/on_demand_scans_form/components/scan_schedule.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';
import dastProfileCreateMutation from 'ee/on_demand_scans_form/graphql/dast_profile_create.mutation.graphql';
import dastProfileUpdateMutation from 'ee/on_demand_scans_form/graphql/dast_profile_update.mutation.graphql';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createApolloProvider from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { redirectTo } from '~/lib/utils/url_utility';
import RefSelector from '~/ref/components/ref_selector.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
import {
  siteProfiles,
  scannerProfiles,
  nonValidatedSiteProfile,
  validatedSiteProfile,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import { itSelectsOnlyAvailableProfile } from './shared_assertions';

const dastSiteValidationDocsPath = '/application_security/dast/index#dast-site-validation';
const projectPath = 'group/project';
const defaultBranch = 'main';
const selectedBranch = 'some-other-branch';
const onDemandScansPath = '/on_demand_scans#saved';
const scannerProfilesLibraryPath = '/security/configuration/profile_library#scanner-profiles';
const siteProfilesLibraryPath = '/security/configuration/profile_library#site-profiles';
const newScannerProfilePath = '/security/configuration/profile_library/dast_scanner_profile/new';
const newSiteProfilePath = `/${projectPath}/-/security/configuration/profile_library`;
const pipelineUrl = `/${projectPath}/pipelines/123`;
const editPath = `/${projectPath}/on_demand_scans_form/1/edit`;
const [passiveScannerProfile, activeScannerProfile] = scannerProfiles;
const dastScan = {
  id: 1,
  branch: { name: 'dev' },
  name: 'My daily scan',
  description: 'Tests for SQL injections',
  dastScannerProfile: { id: passiveScannerProfile.id },
  dastSiteProfile: { id: validatedSiteProfile.id },
};

useLocalStorageSpy();
jest.mock('~/lib/utils/url_utility', () => {
  return {
    ...jest.requireActual('~/lib/utils/url_utility'),
    redirectTo: jest.fn(),
  };
});

const LOCAL_STORAGE_KEY = 'group/project/on-demand-scans-new-form';

describe('OnDemandScansForm', () => {
  let localVue;
  let wrapper;
  let requestHandlers;

  const GlFormInputStub = stubComponent(GlFormInput, {
    template: '<input />',
  });
  const RefSelectorStub = stubComponent(RefSelector, {
    template: '<input />',
  });

  const findForm = () => wrapper.findComponent(GlForm);
  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findHelpPageLink = () => findByTestId('help-page-link');
  const findNameInput = () => findByTestId('dast-scan-name-input');
  const findBranchInput = () => findByTestId('dast-scan-branch-input');
  const findDescriptionInput = () => findByTestId('dast-scan-description-input');
  const findScannerProfilesSelector = () => wrapper.findComponent(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.findComponent(SiteProfileSelector);
  const findAlert = () => findByTestId('on-demand-scan-error');
  const findProfilesConflictAlert = () => findByTestId('on-demand-scans-profiles-conflict-alert');
  const findSubmitButton = () => findByTestId('on-demand-scan-submit-button');
  const findSaveButton = () => findByTestId('on-demand-scan-save-button');
  const findCancelButton = () => findByTestId('on-demand-scan-cancel-button');
  const findProfileSummary = () => findByTestId('selected-profile-summary');
  const findDastProfilesConfigurator = () => wrapper.findComponent(DastProfilesConfigurator);

  const hasSiteProfileAttributes = () => {
    expect(findScannerProfilesSelector().attributes('value')).toBe(dastScan.dastScannerProfile.id);
    expect(findSiteProfilesSelector().attributes('value')).toBe(dastScan.dastSiteProfile.id);
  };

  const setValidFormData = async () => {
    findNameInput().vm.$emit('input', 'My daily scan');
    findBranchInput().vm.$emit('input', selectedBranch);
    findScannerProfilesSelector().vm.$emit('input', passiveScannerProfile.id);
    findSiteProfilesSelector().vm.$emit('input', nonValidatedSiteProfile.id);

    await nextTick();
  };
  const setupSuccess = ({ edit = false } = {}) => {
    wrapper.vm.$apollo.mutate.mockResolvedValue({
      data: {
        [edit ? 'dastProfileUpdate' : 'dastProfileCreate']: {
          dastProfile: { editPath },
          pipelineUrl,
          errors: [],
        },
      },
    });
    return setValidFormData();
  };
  const selectProfile = (component) => async (profile) => {
    wrapper.findComponent(component).vm.$emit('input', profile.id);
    await nextTick();
  };
  const selectScannerProfile = selectProfile(ScannerProfileSelector);
  const selectSiteProfile = selectProfile(SiteProfileSelector);

  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });
  const saveScan = () => findSaveButton().vm.$emit('click');

  const createMockApolloProvider = (handlers) => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(scannerProfilesFixtures),
      dastSiteProfiles: jest.fn().mockResolvedValue(siteProfilesFixtures),
      ...handlers,
    };

    return createApolloProvider([
      [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
    ]);
  };

  const createComponentFactory = (mountFn = shallowMount) => (
    options = {},
    withHandlers,
    glFeatures = {},
  ) => {
    localVue = createLocalVue();
    let defaultMocks = {
      $apollo: {
        mutate: jest.fn(),
        queries: {
          scannerProfiles: {},
          siteProfiles: {},
        },
        addSmartQuery: jest.fn(),
      },
    };
    let apolloProvider;
    if (withHandlers) {
      apolloProvider = createMockApolloProvider(withHandlers);
      defaultMocks = {};
    }
    wrapper = mountFn(
      OnDemandScansForm,
      merge(
        {},
        {
          propsData: {
            defaultBranch,
          },
          mocks: defaultMocks,
          provide: {
            projectPath,
            onDemandScansPath,
            scannerProfilesLibraryPath,
            siteProfilesLibraryPath,
            newScannerProfilePath,
            newSiteProfilePath,
            dastSiteValidationDocsPath,
            ...glFeatures,
          },
          stubs: {
            GlFormInput: GlFormInputStub,
            RefSelector: RefSelectorStub,
            LocalStorageSync,
            ScanSchedule: true,
            SectionLayout,
            SectionLoader,
            ConfigurationPageLayout,
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
    );
    return wrapper;
  };
  const createComponent = createComponentFactory(mount);
  const createShallowComponent = createComponentFactory();

  const itClearsLocalStorage = () => {
    it('clears local storage', () => {
      expect(localStorage.removeItem.mock.calls).toEqual([[LOCAL_STORAGE_KEY]]);
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    localStorage.clear();
  });

  itSelectsOnlyAvailableProfile(createShallowComponent);

  describe('when creating a new scan', () => {
    it('renders properly', () => {
      createComponent();

      expect(wrapper.text()).toContain('New on-demand scan');
      expect(wrapper.findComponent(ScanSchedule).exists()).toBe(true);
    });

    it('renders a link to the docs', () => {
      createComponent();
      const link = findHelpPageLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it('populates the branch input with the default branch', () => {
      createComponent();

      expect(findBranchInput().props('value')).toBe(defaultBranch);
    });

    it.each`
      scannerProfilesLoading | siteProfilesLoading | isLoading
      ${true}                | ${true}             | ${true}
      ${false}               | ${true}             | ${true}
      ${true}                | ${false}            | ${true}
      ${false}               | ${false}            | ${false}
    `(
      'sets loading state to $isLoading if scanner profiles loading is $scannerProfilesLoading and site profiles loading is $siteProfilesLoading',
      ({ scannerProfilesLoading, siteProfilesLoading, isLoading }) => {
        createShallowComponent({
          mocks: {
            $apollo: {
              queries: {
                scannerProfiles: { loading: scannerProfilesLoading },
                siteProfiles: { loading: siteProfilesLoading },
              },
            },
          },
        });

        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(isLoading);
      },
    );
  });

  describe('when editing an existing scan', () => {
    describe('when the branch is not present', () => {
      /**
       * It is possible for pre-fetched data not to have a branch, so we must
       * handle this path.
       */
      beforeEach(() => {
        createShallowComponent({
          propsData: {
            ...dastScan,
            branch: null,
          },
        });
      });

      it('sets the branch to the default', () => {
        expect(findBranchInput().props('value')).toBe(defaultBranch);
      });
    });

    describe('when the branch is present', () => {
      beforeEach(() => {
        createShallowComponent({
          propsData: {
            dastScan,
          },
        });
      });

      it('sets the title properly', () => {
        expect(wrapper.text()).toContain('Edit on-demand scan');
      });

      it('populates the fields with passed values', () => {
        expect(findNameInput().attributes('value')).toBe(dastScan.name);
        expect(findBranchInput().props('value')).toBe(dastScan.branch.name);
        expect(findDescriptionInput().attributes('value')).toBe(dastScan.description);
        hasSiteProfileAttributes();
      });
    });
  });

  describe('local storage', () => {
    it('get updated when form is modified', async () => {
      createShallowComponent();

      await setValidFormData();

      expect(localStorage.setItem.mock.calls).toEqual([
        [
          LOCAL_STORAGE_KEY,
          JSON.stringify({
            name: 'My daily scan',
            selectedScannerProfileId: passiveScannerProfile.id,
            selectedSiteProfileId: nonValidatedSiteProfile.id,
            selectedBranch,
          }),
        ],
      ]);
    });

    it('reload the form data when available', async () => {
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({
          name: dastScan.name,
          description: dastScan.description,
          selectedScannerProfileId: dastScan.dastScannerProfile.id,
          selectedSiteProfileId: dastScan.dastSiteProfile.id,
        }),
      );

      createShallowComponent();
      await nextTick();

      expect(findNameInput().attributes('value')).toBe(dastScan.name);
      expect(findDescriptionInput().attributes('value')).toBe(dastScan.description);
      hasSiteProfileAttributes();
    });
  });

  describe('submit button', () => {
    let submitButton;

    beforeEach(() => {
      createShallowComponent();
      submitButton = findSubmitButton();
    });

    it('is disabled while some fields are empty', () => {
      expect(submitButton.props('disabled')).toBe(true);
    });

    it('becomes enabled when form is valid', async () => {
      await setValidFormData();

      expect(submitButton.props('disabled')).toBe(false);
    });
  });

  describe('submission', () => {
    describe.each`
      action      | actionFunction | submitButtonLoading | saveButtonLoading | runAfter | redirectPath
      ${'submit'} | ${submitForm}  | ${true}             | ${false}          | ${true}  | ${pipelineUrl}
      ${'save'}   | ${saveScan}    | ${false}            | ${true}           | ${false} | ${onDemandScansPath}
    `(
      'on $action',
      ({ actionFunction, submitButtonLoading, saveButtonLoading, runAfter, redirectPath }) => {
        describe('with valid form data', () => {
          beforeEach(async () => {
            createShallowComponent();
            await setupSuccess();
            actionFunction();
          });

          it('sets correct button states', async () => {
            const [submitButton, saveButton, cancelButton] = [
              findSubmitButton(),
              findSaveButton(),
              findCancelButton(),
            ];

            expect(submitButton.props('loading')).toBe(submitButtonLoading);
            expect(submitButton.props('disabled')).toBe(!submitButtonLoading);
            expect(saveButton.props('loading')).toBe(saveButtonLoading);
            expect(saveButton.props('disabled')).toBe(!saveButtonLoading);
            expect(cancelButton.props('disabled')).toBe(true);
          });

          it(`triggers dastProfileCreateMutation mutation with runAfterCreate set to ${runAfter}`, () => {
            expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
              mutation: dastProfileCreateMutation,
              variables: {
                input: {
                  name: 'My daily scan',
                  branchName: selectedBranch,
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  fullPath: projectPath,
                  runAfterCreate: runAfter,
                },
              },
            });
          });

          it('redirects to the URL provided in the response', async () => {
            expect(redirectTo).toHaveBeenCalledWith(redirectPath);
          });

          it('does not show an alert', async () => {
            expect(findAlert().exists()).toBe(false);
          });

          itClearsLocalStorage();
        });

        describe('when editing an existing scan', () => {
          beforeEach(async () => {
            createShallowComponent({
              propsData: {
                dastScan,
              },
            });
            await setupSuccess({ edit: true });
            actionFunction();
          });

          it('passes the scan ID to the profile selectors', () => {
            const dastScanId = String(dastScan.id);

            expect(findScannerProfilesSelector().attributes('dast-scan-id')).toBe(dastScanId);
            expect(findSiteProfilesSelector().attributes('dast-scan-id')).toBe(dastScanId);
          });

          it(`triggers dastProfileUpdateMutation mutation with runAfterUpdate set to ${runAfter}`, async () => {
            expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
              mutation: dastProfileUpdateMutation,
              variables: {
                input: {
                  id: 1,
                  name: 'My daily scan',
                  branchName: selectedBranch,
                  description: 'Tests for SQL injections',
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  runAfterUpdate: runAfter,
                },
              },
            });
          });
        });

        it('does not run any mutation if name is empty', () => {
          createShallowComponent();
          setValidFormData();
          findNameInput().vm.$emit('input', '');
          actionFunction();

          expect(wrapper.vm.$apollo.mutate).not.toHaveBeenCalled();
        });
      },
    );

    describe('on top-level error', () => {
      beforeEach(async () => {
        createShallowComponent();
        wrapper.vm.$apollo.mutate.mockRejectedValue();
        await setValidFormData();
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain('Could not run the scan. Please try again.');
      });
    });

    describe('on errors as data', () => {
      const submitWithError = async (errors) => {
        wrapper.vm.$apollo.mutate.mockResolvedValue({
          data: { dastProfileCreate: { pipelineUrl: null, errors } },
        });
        await setValidFormData();
        await submitForm();
      };

      beforeEach(async () => {
        createShallowComponent();
      });

      it('resets loading state', async () => {
        await submitWithError(['error']);

        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert with the returned errors', async () => {
        const errors = ['error#1', 'error#2', 'error#3'];
        await submitWithError(errors);
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        errors.forEach((error) => {
          expect(alert.text()).toContain(error);
        });
      });

      it('properly renders errors containing markup', async () => {
        await submitWithError(['an error <a href="#" data-testid="error-link">with a link</a>']);
        const alert = findAlert();

        expect(alert.text()).toContain('an error with a link');
        expect(alert.find('[data-testid="error-link"]').exists()).toBe(true);
      });
    });
  });

  describe('cancellation', () => {
    beforeEach(() => {
      createShallowComponent();
      findCancelButton().vm.$emit('click');
    });

    itClearsLocalStorage();

    it('redirects to profiles library', () => {
      expect(redirectTo).toHaveBeenCalledWith(onDemandScansPath);
    });
  });

  describe.each`
    description                                  | selectedScannerProfile   | selectedSiteProfile        | hasConflict
    ${'a passive scan and a non-validated site'} | ${passiveScannerProfile} | ${nonValidatedSiteProfile} | ${false}
    ${'a passive scan and a validated site'}     | ${passiveScannerProfile} | ${validatedSiteProfile}    | ${false}
    ${'an active scan and a non-validated site'} | ${activeScannerProfile}  | ${nonValidatedSiteProfile} | ${true}
    ${'an active scan and a validated site'}     | ${activeScannerProfile}  | ${validatedSiteProfile}    | ${false}
  `(
    'profiles conflict prevention',
    ({ description, selectedScannerProfile, selectedSiteProfile, hasConflict }) => {
      const setFormData = async () => {
        findScannerProfilesSelector().vm.$emit('input', selectedScannerProfile.id);
        findSiteProfilesSelector().vm.$emit('input', selectedSiteProfile.id);
        await nextTick();
      };

      it(
        hasConflict
          ? `warns about conflicting profiles when user selects ${description}`
          : `does not report any conflict when user selects ${description}`,
        async () => {
          createShallowComponent();
          await setFormData();

          expect(findProfilesConflictAlert().exists()).toBe(hasConflict);
          expect(findSubmitButton().props('disabled')).toBe(hasConflict);
        },
      );
    },
  );

  describe('scanner profile summary', () => {
    const [{ id }] = scannerProfiles;

    beforeEach(() => {
      createComponent();
    });

    it('renders profile summary when a valid profile is selected', async () => {
      await selectScannerProfile({ id });

      expect(findProfileSummary().exists()).toBe(true);
    });

    it('does not render the summary provided an invalid profile ID', async () => {
      await selectScannerProfile({ id: 'gid://gitlab/DastScannerProfile/123' });

      expect(findProfileSummary().exists()).toBe(false);
    });
  });

  describe('site profile summary', () => {
    const [{ id }] = siteProfiles;

    beforeEach(() => {
      createComponent();
    });

    it('renders profile summary when a valid profile is selected', async () => {
      await selectSiteProfile({ id });

      expect(findProfileSummary().exists()).toBe(true);
    });

    it('does not render the summary provided an invalid profile ID', async () => {
      await selectSiteProfile({ id: 'gid://gitlab/DastSiteProfile/123' });

      expect(findProfileSummary().exists()).toBe(false);
    });
  });

  describe('populate profiles from query params', () => {
    const [siteProfile] = siteProfiles;
    const [scannerProfile] = scannerProfiles;

    it('scanner profile', () => {
      setWindowLocation(`?scanner_profile_id=${getIdFromGraphQLId(scannerProfile.id)}`);
      createShallowComponent();

      expect(findScannerProfilesSelector().attributes('value')).toBe(scannerProfile.id);
    });

    it('site profile', () => {
      setWindowLocation(`?site_profile_id=${getIdFromGraphQLId(siteProfile.id)}`);
      createShallowComponent();

      expect(findSiteProfilesSelector().attributes('value')).toBe(siteProfile.id);
    });

    it('both scanner & site profile', () => {
      setWindowLocation(
        `?site_profile_id=${getIdFromGraphQLId(
          siteProfile.id,
        )}&scanner_profile_id=${getIdFromGraphQLId(scannerProfile.id)}`,
      );
      createShallowComponent();

      expect(findSiteProfilesSelector().attributes('value')).toBe(siteProfile.id);
      expect(findScannerProfilesSelector().attributes('value')).toBe(scannerProfile.id);
    });

    it('when local storage data is available', async () => {
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({
          selectedScannerProfileId: dastScan.dastScannerProfile.id,
          selectedSiteProfileId: dastScan.dastSiteProfile.id,
        }),
      );

      createShallowComponent();
      await nextTick();

      hasSiteProfileAttributes();
    });
  });

  describe('when no repository exists', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          /**
           * The assumption here is that, if a default branch is not defined, then the project
           * does not have a repository.
           */
          defaultBranch: '',
        },
      });
    });

    it('shows an error message', () => {
      expect(wrapper.text()).toContain(
        'You must create a repository within your project to run an on-demand scan.',
      );
    });
  });

  describe('With `dastUiRedesign` feature flag on', () => {
    beforeEach(() => {
      createShallowComponent({}, false, {
        glFeatures: {
          dastUiRedesign: true,
        },
      });
    });

    it('should have correct component rendered', async () => {
      expect(findDastProfilesConfigurator().exists()).toBe(true);
      expect(findScannerProfilesSelector().exists()).toBe(false);
      expect(findSiteProfilesSelector().exists()).toBe(false);
    });
  });

  describe('With `dastUiRedesign` feature flag off', () => {
    beforeEach(() => {
      createShallowComponent({}, false, {
        glFeatures: {
          dastUiRedesign: false,
        },
      });
    });

    it('should have correct component rendered', async () => {
      expect(findDastProfilesConfigurator().exists()).toBe(false);
      expect(findScannerProfilesSelector().exists()).toBe(true);
      expect(findSiteProfilesSelector().exists()).toBe(true);
    });
  });
});
