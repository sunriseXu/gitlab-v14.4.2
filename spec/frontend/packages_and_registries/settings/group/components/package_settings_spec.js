import Vue, { nextTick } from 'vue';
import { GlToggle } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExceptionsInput from '~/packages_and_registries/settings/group/components/exceptions_input.vue';
import component from '~/packages_and_registries/settings/group/components/packages_settings.vue';
import {
  DUPLICATES_TOGGLE_LABEL,
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
} from '~/packages_and_registries/settings/group/constants';

import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import {
  packageSettings,
  groupPackageSettingsMock,
  groupPackageSettingsMutationMock,
  groupPackageSettingsMutationErrorMock,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/packages_and_registries/settings/group/graphql/utils/optimistic_responses');

describe('Packages Settings', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    groupPath: 'foo_group_path',
  };

  const mountComponent = ({
    mountFn = shallowMountExtended,
    mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock()),
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[updateNamespacePackageSettings, mutationResolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(component, {
      apolloProvider,
      provide: defaultProvide,
      propsData: {
        packageSettings: packageSettings(),
      },
      stubs: {
        SettingsBlock,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findDescription = () => wrapper.findByTestId('description');
  const findMavenSettings = () => wrapper.findByTestId('maven-settings');
  const findGenericSettings = () => wrapper.findByTestId('generic-settings');

  const findMavenDuplicatedSettingsToggle = () => findMavenSettings().findComponent(GlToggle);
  const findGenericDuplicatedSettingsToggle = () => findGenericSettings().findComponent(GlToggle);
  const findMavenDuplicatedSettingsExceptionsInput = () =>
    findMavenSettings().findComponent(ExceptionsInput);
  const findGenericDuplicatedSettingsExceptionsInput = () =>
    findGenericSettings().findComponent(ExceptionsInput);

  const fillApolloCache = () => {
    apolloProvider.defaultClient.cache.writeQuery({
      query: getGroupPackagesSettingsQuery,
      variables: {
        fullPath: defaultProvide.groupPath,
      },
      ...groupPackageSettingsMock,
    });
  };

  const emitMavenSettingsUpdate = (override) => {
    findGenericDuplicatedSettingsExceptionsInput().vm.$emit('update', {
      mavenDuplicateExceptionRegex: ')',
      ...override,
    });
  };

  it('renders a settings block', () => {
    mountComponent();

    expect(findSettingsBlock().exists()).toBe(true);
  });

  it('has the correct header text', () => {
    mountComponent();

    expect(wrapper.text()).toContain(PACKAGE_SETTINGS_HEADER);
  });

  it('has the correct description text', () => {
    mountComponent();

    expect(findDescription().text()).toMatchInterpolatedText(PACKAGE_SETTINGS_DESCRIPTION);
  });

  describe('maven settings', () => {
    it('exists', () => {
      mountComponent({ mountFn: mountExtended });

      expect(findMavenSettings().find('td').text()).toBe('Maven');
    });

    it('renders toggle', () => {
      mountComponent({ mountFn: mountExtended });

      const { mavenDuplicatesAllowed } = packageSettings();

      expect(findMavenDuplicatedSettingsToggle().exists()).toBe(true);

      expect(findMavenDuplicatedSettingsToggle().props()).toMatchObject({
        label: DUPLICATES_TOGGLE_LABEL,
        value: mavenDuplicatesAllowed,
        disabled: false,
        labelPosition: 'hidden',
      });
    });

    it('renders ExceptionsInput and assigns duplication allowness and exception props', () => {
      mountComponent({ mountFn: mountExtended });

      const { mavenDuplicatesAllowed, mavenDuplicateExceptionRegex } = packageSettings();

      expect(findMavenDuplicatedSettingsExceptionsInput().exists()).toBe(true);

      expect(findMavenDuplicatedSettingsExceptionsInput().props()).toMatchObject({
        duplicatesAllowed: mavenDuplicatesAllowed,
        duplicateExceptionRegex: mavenDuplicateExceptionRegex,
        duplicateExceptionRegexError: '',
        loading: false,
        name: 'mavenDuplicateExceptionRegex',
        id: 'maven-duplicated-settings-regex-input',
      });
    });

    it('on update event calls the mutation', () => {
      const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock());
      mountComponent({ mountFn: mountExtended, mutationResolver });

      fillApolloCache();

      emitMavenSettingsUpdate();

      expect(mutationResolver).toHaveBeenCalledWith({
        input: { mavenDuplicateExceptionRegex: ')', namespacePath: 'foo_group_path' },
      });
    });
  });

  describe('generic settings', () => {
    it('exists', () => {
      mountComponent({ mountFn: mountExtended });

      expect(findGenericSettings().find('td').text()).toBe('Generic');
    });

    it('renders toggle', () => {
      mountComponent({ mountFn: mountExtended });

      const { genericDuplicatesAllowed } = packageSettings();

      expect(findGenericDuplicatedSettingsToggle().exists()).toBe(true);
      expect(findGenericDuplicatedSettingsToggle().props()).toMatchObject({
        label: DUPLICATES_TOGGLE_LABEL,
        value: genericDuplicatesAllowed,
        disabled: false,
        labelPosition: 'hidden',
      });
    });

    it('renders ExceptionsInput and assigns duplication allowness and exception props', async () => {
      mountComponent({ mountFn: mountExtended });

      const { genericDuplicatesAllowed, genericDuplicateExceptionRegex } = packageSettings();

      expect(findGenericDuplicatedSettingsExceptionsInput().props()).toMatchObject({
        duplicatesAllowed: genericDuplicatesAllowed,
        duplicateExceptionRegex: genericDuplicateExceptionRegex,
        duplicateExceptionRegexError: '',
        loading: false,
        name: 'genericDuplicateExceptionRegex',
        id: 'generic-duplicated-settings-regex-input',
      });
    });

    it('on update event calls the mutation', async () => {
      const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationMock());
      mountComponent({ mountFn: mountExtended, mutationResolver });

      fillApolloCache();

      findGenericDuplicatedSettingsExceptionsInput().vm.$emit('update', {
        genericDuplicateExceptionRegex: ')',
      });

      expect(mutationResolver).toHaveBeenCalledWith({
        input: { genericDuplicateExceptionRegex: ')', namespacePath: 'foo_group_path' },
      });
    });
  });

  describe('settings update', () => {
    describe('success state', () => {
      beforeEach(() => {
        mountComponent({ mountFn: mountExtended });
      });

      it('emits a success event', async () => {
        fillApolloCache();
        emitMavenSettingsUpdate();

        await waitForPromises();

        expect(wrapper.emitted('success')).toEqual([[]]);
      });

      it('has an optimistic response', () => {
        const mavenDuplicateExceptionRegex = 'latest[main]something';

        fillApolloCache();

        expect(
          findGenericDuplicatedSettingsExceptionsInput().props('duplicateExceptionRegex'),
        ).toBe('');

        emitMavenSettingsUpdate({ mavenDuplicateExceptionRegex });

        expect(updateGroupPackagesSettingsOptimisticResponse).toHaveBeenCalledWith({
          ...packageSettings(),
          mavenDuplicateExceptionRegex,
        });
      });
    });

    describe('errors', () => {
      it('mutation payload with root level errors', async () => {
        // note this is a complex test that covers all the path around errors that are shown in the form
        // it's one single it case, due to the expensive preparation and execution
        const mutationResolver = jest.fn().mockResolvedValue(groupPackageSettingsMutationErrorMock);
        mountComponent({ mountFn: mountExtended, mutationResolver });

        fillApolloCache();

        emitMavenSettingsUpdate();

        await waitForPromises();

        // errors are bound to the component
        expect(
          findMavenDuplicatedSettingsExceptionsInput().props('duplicateExceptionRegexError'),
        ).toBe(groupPackageSettingsMutationErrorMock.errors[0].extensions.problems[0].message);

        // general error message is shown

        expect(wrapper.emitted('error')).toEqual([[]]);

        emitMavenSettingsUpdate();

        await nextTick();

        // errors are reset on mutation call
        expect(
          findMavenDuplicatedSettingsExceptionsInput().props('duplicateExceptionRegexError'),
        ).toBe('');
      });

      it.each`
        type         | mutationResolver
        ${'local'}   | ${jest.fn().mockResolvedValue(groupPackageSettingsMutationMock({ errors: ['foo'] }))}
        ${'network'} | ${jest.fn().mockRejectedValue()}
      `('mutation payload with $type error', async ({ mutationResolver }) => {
        mountComponent({ mountFn: mountExtended, mutationResolver });

        fillApolloCache();
        emitMavenSettingsUpdate();

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[]]);
      });
    });
  });
});
