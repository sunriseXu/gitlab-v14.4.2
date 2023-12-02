import { GlSprintf, GlToggle } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import ProjectFeatureSetting from '~/pages/projects/shared/permissions/components/project_feature_setting.vue';
import settingsPanel from '~/pages/projects/shared/permissions/components/settings_panel.vue';
import {
  featureAccessLevel,
  visibilityLevelDescriptions,
} from '~/pages/projects/shared/permissions/constants';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
} from '~/visibility_level/constants';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';

const defaultProps = {
  currentSettings: {
    visibilityLevel: 10,
    requestAccessEnabled: true,
    issuesAccessLevel: 20,
    repositoryAccessLevel: 20,
    forkingAccessLevel: 20,
    mergeRequestsAccessLevel: 20,
    buildsAccessLevel: 20,
    wikiAccessLevel: 20,
    snippetsAccessLevel: 20,
    operationsAccessLevel: 20,
    metricsDashboardAccessLevel: 20,
    pagesAccessLevel: 10,
    analyticsAccessLevel: 20,
    containerRegistryAccessLevel: 20,
    lfsEnabled: true,
    emailsDisabled: false,
    packagesEnabled: true,
    showDefaultAwardEmojis: true,
    warnAboutPotentiallyUnwantedCharacters: true,
  },
  isGitlabCom: true,
  canDisableEmails: true,
  canChangeVisibilityLevel: true,
  allowedVisibilityOptions: [0, 10, 20],
  visibilityHelpPath: '/help/public_access/public_access',
  registryAvailable: false,
  registryHelpPath: '/help/user/packages/container_registry/index',
  lfsAvailable: true,
  lfsHelpPath: '/help/topics/git/lfs/index',
  lfsObjectsExist: false,
  lfsObjectsRemovalHelpPath: `/help/topics/git/lfs/index#removing-objects-from-lfs`,
  pagesAvailable: true,
  pagesAccessControlEnabled: false,
  pagesAccessControlForced: false,
  pagesHelpPath: '/help/user/project/pages/introduction#gitlab-pages-access-control',
  packagesAvailable: false,
  packagesHelpPath: '/help/user/packages/index',
  requestCveAvailable: true,
  confirmationPhrase: 'my-fake-project',
  showVisibilityConfirmModal: false,
  membersPagePath: '/my-fake-project/-/project_members',
};

const FEATURE_ACCESS_LEVEL_ANONYMOUS = 30;

describe('Settings Panel', () => {
  let wrapper;

  const mountComponent = (
    { currentSettings = {}, glFeatures = {}, stubs = {}, ...customProps } = {},
    mountFn = shallowMount,
  ) => {
    const propsData = {
      ...defaultProps,
      ...customProps,
      currentSettings: { ...defaultProps.currentSettings, ...currentSettings },
    };

    return mountFn(settingsPanel, {
      propsData,
      provide: {
        glFeatures: {
          packageRegistryAccessLevel: false,
          ...glFeatures,
        },
      },
      stubs,
    });
  };

  const findLFSSettingsRow = () => wrapper.findComponent({ ref: 'git-lfs-settings' });
  const findLFSSettingsMessage = () => findLFSSettingsRow().find('p');
  const findLFSFeatureToggle = () => findLFSSettingsRow().findComponent(GlToggle);
  const findRepositoryFeatureProjectRow = () =>
    wrapper.findComponent({ ref: 'repository-settings' });
  const findRepositoryFeatureSetting = () =>
    findRepositoryFeatureProjectRow().findComponent(ProjectFeatureSetting);
  const findProjectVisibilitySettings = () =>
    wrapper.findComponent({ ref: 'project-visibility-settings' });
  const findIssuesSettingsRow = () => wrapper.findComponent({ ref: 'issues-settings' });
  const findAnalyticsRow = () => wrapper.findComponent({ ref: 'analytics-settings' });
  const findProjectVisibilityLevelInput = () => wrapper.find('[name="project[visibility_level]"]');
  const findRequestAccessEnabledInput = () =>
    wrapper.find('[name="project[request_access_enabled]"]');
  const findMergeRequestsAccessLevelInput = () =>
    wrapper.find('[name="project[project_feature_attributes][merge_requests_access_level]"]');
  const findForkingAccessLevelInput = () =>
    wrapper.find('[name="project[project_feature_attributes][forking_access_level]"]');
  const findBuildsAccessLevelInput = () =>
    wrapper.find('[name="project[project_feature_attributes][builds_access_level]"]');
  const findContainerRegistrySettings = () =>
    wrapper.findComponent({ ref: 'container-registry-settings' });
  const findContainerRegistryPublicNoteGlSprintfComponent = () =>
    findContainerRegistrySettings().findComponent(GlSprintf);
  const findContainerRegistryAccessLevelInput = () =>
    wrapper.find('[name="project[project_feature_attributes][container_registry_access_level]"]');
  const findPackageSettings = () => wrapper.findComponent({ ref: 'package-settings' });
  const findPackageAccessLevel = () =>
    wrapper.find('[data-testid="package-registry-access-level"]');
  const findPackageAccessLevels = () =>
    wrapper.find('[name="project[project_feature_attributes][package_registry_access_level]"]');
  const findPackagesEnabledInput = () => wrapper.find('[name="project[packages_enabled]"]');
  const findPagesSettings = () => wrapper.findComponent({ ref: 'pages-settings' });
  const findPagesAccessLevels = () =>
    wrapper.find('[name="project[project_feature_attributes][pages_access_level]"]');
  const findEmailSettings = () => wrapper.findComponent({ ref: 'email-settings' });
  const findShowDefaultAwardEmojis = () =>
    wrapper.find('input[name="project[project_setting_attributes][show_default_award_emojis]"]');
  const findWarnAboutPuc = () =>
    wrapper.find(
      'input[name="project[project_setting_attributes][warn_about_potentially_unwanted_characters]"]',
    );
  const findMetricsVisibilitySettings = () =>
    wrapper.findComponent({ ref: 'metrics-visibility-settings' });
  const findMetricsVisibilityInput = () =>
    findMetricsVisibilitySettings().findComponent(ProjectFeatureSetting);
  const findOperationsSettings = () => wrapper.findComponent({ ref: 'operations-settings' });
  const findOperationsVisibilityInput = () =>
    findOperationsSettings().findComponent(ProjectFeatureSetting);
  const findConfirmDangerButton = () => wrapper.findComponent(ConfirmDanger);
  const findEnvironmentsSettings = () => wrapper.findComponent({ ref: 'environments-settings' });
  const findFeatureFlagsSettings = () => wrapper.findComponent({ ref: 'feature-flags-settings' });
  const findReleasesSettings = () => wrapper.findComponent({ ref: 'environments-settings' });
  const findMonitorSettings = () => wrapper.findComponent({ ref: 'monitor-settings' });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Project Visibility', () => {
    it('should set the project visibility help path', () => {
      wrapper = mountComponent();

      expect(findProjectVisibilitySettings().props('helpPath')).toBe(
        defaultProps.visibilityHelpPath,
      );
    });

    it('should not disable the visibility level dropdown', () => {
      wrapper = mountComponent({ canChangeVisibilityLevel: true });

      expect(findProjectVisibilityLevelInput().attributes('disabled')).toBeUndefined();
    });

    it('should disable the visibility level dropdown', () => {
      wrapper = mountComponent({ canChangeVisibilityLevel: false });

      expect(findProjectVisibilityLevelInput().attributes('disabled')).toBe('disabled');
    });

    it.each`
      option                               | allowedOptions                                                                                            | disabled
      ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${[VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_INTERNAL_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER]} | ${false}
      ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${[VISIBILITY_LEVEL_INTERNAL_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER]}                                   | ${true}
      ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${[VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_INTERNAL_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER]} | ${false}
      ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${[VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER]}                                    | ${true}
      ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${[VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_INTERNAL_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER]} | ${false}
      ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${[VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_INTERNAL_INTEGER]}                                  | ${true}
    `(
      'sets disabled to $disabled for the visibility option $option when given $allowedOptions',
      ({ option, allowedOptions, disabled }) => {
        wrapper = mountComponent({ allowedVisibilityOptions: allowedOptions });

        const attributeValue = findProjectVisibilityLevelInput()
          .find(`option[value="${option}"]`)
          .attributes('disabled');

        const expected = disabled ? 'disabled' : undefined;

        expect(attributeValue).toBe(expected);
      },
    );

    it('should set the visibility level description based upon the selected visibility level', () => {
      wrapper = mountComponent({ stubs: { GlSprintf } });

      findProjectVisibilityLevelInput().setValue(VISIBILITY_LEVEL_INTERNAL_INTEGER);

      expect(findProjectVisibilitySettings().text()).toContain(
        visibilityLevelDescriptions[VISIBILITY_LEVEL_INTERNAL_INTEGER],
      );
    });

    it('should show the request access checkbox if the visibility level is not private', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER },
      });

      expect(findRequestAccessEnabledInput().exists()).toBe(true);
    });

    it('should not show the request access checkbox if the visibility level is private', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER },
      });

      expect(findRequestAccessEnabledInput().exists()).toBe(false);
    });

    it('does not require confirmation if the visibility is reduced', async () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER },
      });

      expect(findConfirmDangerButton().exists()).toBe(false);

      await findProjectVisibilityLevelInput().setValue(VISIBILITY_LEVEL_PRIVATE_INTEGER);

      expect(findConfirmDangerButton().exists()).toBe(false);
    });

    describe('showVisibilityConfirmModal=true', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          currentSettings: { visibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER },
          showVisibilityConfirmModal: true,
        });
      });

      it('will render the confirmation dialog if the visibility is reduced', async () => {
        expect(findConfirmDangerButton().exists()).toBe(false);

        await findProjectVisibilityLevelInput().setValue(VISIBILITY_LEVEL_PRIVATE_INTEGER);

        expect(findConfirmDangerButton().exists()).toBe(true);
      });

      it('emits the `confirm` event when the reduce visibility warning is confirmed', async () => {
        expect(wrapper.emitted('confirm')).toBeUndefined();

        await findProjectVisibilityLevelInput().setValue(VISIBILITY_LEVEL_PRIVATE_INTEGER);
        await findConfirmDangerButton().vm.$emit('confirm');

        expect(wrapper.emitted('confirm')).toHaveLength(1);
      });
    });
  });

  describe('Issues settings', () => {
    it('has label for CVE request toggle', () => {
      wrapper = mountComponent();

      expect(findIssuesSettingsRow().findComponent(GlToggle).props('label')).toBe(
        settingsPanel.i18n.cve_request_toggle_label,
      );
    });
  });

  describe('Repository', () => {
    it('should set the repository help text when the visibility level is set to private', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER },
      });

      expect(findRepositoryFeatureProjectRow().props('helpText')).toBe(
        'View and edit files in this project.',
      );
    });

    it('should set the repository help text with a read access warning when the visibility level is set to non-private', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER },
      });

      expect(findRepositoryFeatureProjectRow().props('helpText')).toBe(
        'View and edit files in this project. Non-project members have only read access.',
      );
    });
  });

  describe('Merge requests', () => {
    it('should enable the merge requests access level input when the repository is enabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
      });

      expect(findMergeRequestsAccessLevelInput().props('disabledInput')).toBe(false);
    });

    it('should disable the merge requests access level input when the repository is disabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
      });

      expect(findMergeRequestsAccessLevelInput().props('disabledInput')).toBe(true);
    });
  });

  describe('Forks', () => {
    it('should enable the forking access level input when the repository is enabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
      });

      expect(findForkingAccessLevelInput().props('disabledInput')).toBe(false);
    });

    it('should disable the forking access level input when the repository is disabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
      });

      expect(findForkingAccessLevelInput().props('disabledInput')).toBe(true);
    });
  });

  describe('CI/CD', () => {
    it('should enable the builds access level input when the repository is enabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
      });

      expect(findBuildsAccessLevelInput().props('disabledInput')).toBe(false);
    });

    it('should disable the builds access level input when the repository is disabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
      });

      expect(findBuildsAccessLevelInput().props('disabledInput')).toBe(true);
    });
  });

  describe('Container registry', () => {
    it('should show the container registry settings if the registry is available', () => {
      wrapper = mountComponent({ registryAvailable: true });

      expect(findContainerRegistrySettings().exists()).toBe(true);
    });

    it('should hide the container registry settings if the registry is not available', () => {
      wrapper = mountComponent({ registryAvailable: false });

      expect(findContainerRegistrySettings().exists()).toBe(false);
    });

    it('should set the container registry settings help path', () => {
      wrapper = mountComponent({ registryAvailable: true });

      expect(findContainerRegistrySettings().props('helpPath')).toBe(defaultProps.registryHelpPath);
    });

    it('should show the container registry public note if the visibility level is public and the registry is available', () => {
      wrapper = mountComponent({
        currentSettings: {
          visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
          containerRegistryAccessLevel: featureAccessLevel.EVERYONE,
        },
        registryAvailable: true,
      });

      expect(findContainerRegistryPublicNoteGlSprintfComponent().exists()).toBe(true);
      expect(findContainerRegistryPublicNoteGlSprintfComponent().attributes('message')).toContain(
        `Note: The container registry is always visible when a project is public and the container registry is set to '%{access_level_description}'`,
      );
    });

    it('should hide the container registry public note if the visibility level is public but the registry is private', () => {
      wrapper = mountComponent({
        currentSettings: {
          visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
          containerRegistryAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
        },
        registryAvailable: true,
      });

      expect(findContainerRegistryPublicNoteGlSprintfComponent().exists()).toBe(false);
    });

    it('should hide the container registry public note if the visibility level is private and the registry is available', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER },
        registryAvailable: true,
      });

      expect(findContainerRegistryPublicNoteGlSprintfComponent().exists()).toBe(false);
    });

    it('has label for the toggle', () => {
      wrapper = mountComponent({
        currentSettings: { visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER },
        registryAvailable: true,
      });

      expect(findContainerRegistryAccessLevelInput().props('label')).toBe(
        settingsPanel.i18n.containerRegistryLabel,
      );
    });
  });

  describe('Git Large File Storage', () => {
    it('should show the LFS settings if LFS is available', () => {
      wrapper = mountComponent({ lfsAvailable: true });

      expect(findLFSSettingsRow().exists()).toBe(true);
    });

    it('should hide the LFS settings if LFS is not available', () => {
      wrapper = mountComponent({ lfsAvailable: false });

      expect(findLFSSettingsRow().exists()).toBe(false);
    });

    it('should set the LFS settings help path', () => {
      wrapper = mountComponent();
      expect(findLFSSettingsRow().props('helpPath')).toBe(defaultProps.lfsHelpPath);
    });

    it('should enable the LFS input when the repository is enabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        lfsAvailable: true,
      });

      expect(findLFSFeatureToggle().props('disabled')).toBe(false);
    });

    it('should disable the LFS input when the repository is disabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
        lfsAvailable: true,
      });

      expect(findLFSFeatureToggle().props('disabled')).toBe(true);
    });

    it('has label for toggle', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        lfsAvailable: true,
      });

      expect(findLFSFeatureToggle().props('label')).toBe(settingsPanel.i18n.lfsLabel);
    });

    it('should not change lfsEnabled when disabling the repository', async () => {
      // mount over shallowMount, because we are aiming to test rendered state of toggle
      wrapper = mountComponent({ currentSettings: { lfsEnabled: true } }, mount);

      const repositoryFeatureToggleButton = findRepositoryFeatureSetting().find('button');
      const lfsFeatureToggleButton = findLFSFeatureToggle().find('button');
      const isToggleButtonChecked = (toggleButton) => toggleButton.classes('is-checked');

      // assert the initial state
      expect(isToggleButtonChecked(lfsFeatureToggleButton)).toBe(true);
      expect(isToggleButtonChecked(repositoryFeatureToggleButton)).toBe(true);

      await repositoryFeatureToggleButton.trigger('click');

      expect(isToggleButtonChecked(repositoryFeatureToggleButton)).toBe(false);
      // LFS toggle should still be checked
      expect(isToggleButtonChecked(lfsFeatureToggleButton)).toBe(true);
    });

    describe.each`
      lfsObjectsExist | lfsEnabled | isShown
      ${true}         | ${true}    | ${false}
      ${true}         | ${false}   | ${true}
      ${false}        | ${true}    | ${false}
      ${false}        | ${false}   | ${false}
    `(
      'with (lfsObjectsExist = $lfsObjectsExist, lfsEnabled = $lfsEnabled)',
      ({ lfsObjectsExist, lfsEnabled, isShown }) => {
        beforeEach(() => {
          wrapper = mountComponent({ lfsObjectsExist, currentSettings: { lfsEnabled } }, mount);
        });

        if (isShown) {
          it('shows warning message', () => {
            const message = findLFSSettingsMessage();
            const link = message.find('a');

            expect(message.text()).toContain(
              'LFS objects from this repository are available to forks.',
            );
            expect(link.text()).toBe('How do I remove them?');
            expect(link.attributes('href')).toBe(
              '/help/topics/git/lfs/index#removing-objects-from-lfs',
            );
          });
        } else {
          it('does not show warning message', () => {
            expect(findLFSSettingsMessage().exists()).toBe(false);
          });
        }
      },
    );
  });

  describe('Packages', () => {
    it('should show the packages settings if packages are available', () => {
      wrapper = mountComponent({ packagesAvailable: true });

      expect(findPackageSettings().exists()).toBe(true);
    });

    it('should hide the packages settings if packages are not available', () => {
      wrapper = mountComponent({ packagesAvailable: false });

      expect(findPackageSettings().exists()).toBe(false);
    });

    it('should set the package settings help path', () => {
      wrapper = mountComponent({ packagesAvailable: true });

      expect(findPackageSettings().props('helpPath')).toBe(defaultProps.packagesHelpPath);
    });

    it('should enable the packages input when the repository is enabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        packagesAvailable: true,
      });

      expect(findPackagesEnabledInput().props('disabled')).toBe(false);
    });

    it('should disable the packages input when the repository is disabled', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.NOT_ENABLED },
        packagesAvailable: true,
      });

      expect(findPackagesEnabledInput().props('disabled')).toBe(true);
    });

    it('has label for toggle', () => {
      wrapper = mountComponent({
        currentSettings: { repositoryAccessLevel: featureAccessLevel.EVERYONE },
        packagesAvailable: true,
      });

      expect(findPackagesEnabledInput().findComponent(GlToggle).props('label')).toBe(
        settingsPanel.i18n.packagesLabel,
      );
    });

    it('should hide the package access level settings', () => {
      wrapper = mountComponent();

      expect(findPackageAccessLevel().exists()).toBe(false);
    });

    describe('packageRegistryAccessLevel feature flag = true', () => {
      it('should hide the packages settings', () => {
        wrapper = mountComponent({
          glFeatures: { packageRegistryAccessLevel: true },
          packagesAvailable: true,
        });

        expect(findPackageSettings().exists()).toBe(false);
      });

      it('should hide the package access level settings with packagesAvailable = false', () => {
        wrapper = mountComponent({ glFeatures: { packageRegistryAccessLevel: true } });

        expect(findPackageAccessLevel().exists()).toBe(false);
      });

      it('renders the package access level settings with packagesAvailable = true', () => {
        wrapper = mountComponent({
          glFeatures: { packageRegistryAccessLevel: true },
          packagesAvailable: true,
        });

        expect(findPackageAccessLevel().exists()).toBe(true);
      });

      it.each`
        visibilityLevel                      | output
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${[[featureAccessLevel.PROJECT_MEMBERS, 'Only Project Members'], [30, 'Everyone']]}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${[[featureAccessLevel.EVERYONE, 'Everyone With Access'], [30, 'Everyone']]}
        ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${[[30, 'Everyone']]}
      `(
        'renders correct options when visibilityLevel is $visibilityLevel',
        async ({ visibilityLevel, output }) => {
          wrapper = mountComponent({
            glFeatures: { packageRegistryAccessLevel: true },
            packagesAvailable: true,
            currentSettings: {
              visibilityLevel,
            },
          });

          expect(findPackageAccessLevels().props('options')).toStrictEqual(output);
        },
      );

      it.each`
        initialProjectVisibilityLevel        | newProjectVisibilityLevel            | initialPackageRegistryOption          | expectedPackageRegistryOption
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${featureAccessLevel.PROJECT_MEMBERS} | ${featureAccessLevel.EVERYONE}
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${featureAccessLevel.PROJECT_MEMBERS} | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${featureAccessLevel.EVERYONE}        | ${featureAccessLevel.PROJECT_MEMBERS}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${featureAccessLevel.EVERYONE}        | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}
        ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${featureAccessLevel.PROJECT_MEMBERS}
        ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.NOT_ENABLED}
        ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${FEATURE_ACCESS_LEVEL_ANONYMOUS}     | ${featureAccessLevel.EVERYONE}
      `(
        'changes option from $initialPackageRegistryOption to $expectedPackageRegistryOption when visibilityLevel changed from $initialProjectVisibilityLevel to $newProjectVisibilityLevel',
        async ({
          initialProjectVisibilityLevel,
          newProjectVisibilityLevel,
          initialPackageRegistryOption,
          expectedPackageRegistryOption,
        }) => {
          wrapper = mountComponent({
            glFeatures: { packageRegistryAccessLevel: true },
            packagesAvailable: true,
            currentSettings: {
              visibilityLevel: initialProjectVisibilityLevel,
              packageRegistryAccessLevel: initialPackageRegistryOption,
            },
          });

          await findProjectVisibilityLevelInput().setValue(newProjectVisibilityLevel);

          expect(findPackageAccessLevels().props('value')).toStrictEqual(
            expectedPackageRegistryOption,
          );
        },
      );
    });
  });

  describe('Pages', () => {
    it.each`
      visibilityLevel                      | pagesAccessControlForced | output
      ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${true}                  | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access']]}
      ${VISIBILITY_LEVEL_PRIVATE_INTEGER}  | ${false}                 | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access'], [30, 'Everyone']]}
      ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${true}                  | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access']]}
      ${VISIBILITY_LEVEL_INTERNAL_INTEGER} | ${false}                 | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access'], [30, 'Everyone']]}
      ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${true}                  | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access']]}
      ${VISIBILITY_LEVEL_PUBLIC_INTEGER}   | ${false}                 | ${[[VISIBILITY_LEVEL_INTERNAL_INTEGER, 'Only Project Members'], [VISIBILITY_LEVEL_PUBLIC_INTEGER, 'Everyone With Access'], [30, 'Everyone']]}
    `(
      'renders correct options when pagesAccessControlForced is $pagesAccessControlForced and visibilityLevel is $visibilityLevel',
      async ({ visibilityLevel, pagesAccessControlForced, output }) => {
        wrapper = mountComponent({
          pagesAvailable: true,
          pagesAccessControlEnabled: true,
          pagesAccessControlForced,
        });

        await findProjectVisibilityLevelInput().trigger('change', visibilityLevel);

        expect(findPagesAccessLevels().props('options')).toStrictEqual(output);
      },
    );

    it.each`
      pagesAvailable | pagesAccessControlEnabled | visibility
      ${true}        | ${true}                   | ${'show'}
      ${true}        | ${false}                  | ${'hide'}
      ${false}       | ${true}                   | ${'hide'}
      ${false}       | ${false}                  | ${'hide'}
    `(
      'should $visibility the page settings if pagesAvailable is $pagesAvailable and pagesAccessControlEnabled is $pagesAccessControlEnabled',
      ({ pagesAvailable, pagesAccessControlEnabled, visibility }) => {
        wrapper = mountComponent({ pagesAvailable, pagesAccessControlEnabled });

        expect(findPagesSettings().exists()).toBe(visibility === 'show');
      },
    );

    it('should set the pages settings help path', () => {
      wrapper = mountComponent({ pagesAvailable: true, pagesAccessControlEnabled: true });

      expect(findPagesSettings().props('helpPath')).toBe(defaultProps.pagesHelpPath);
    });
  });

  describe('Email notifications', () => {
    it('should show the disable email notifications input if emails an be disabled', () => {
      wrapper = mountComponent({ canDisableEmails: true });

      expect(findEmailSettings().exists()).toBe(true);
    });

    it('should hide the disable email notifications input if emails cannot be disabled', () => {
      wrapper = mountComponent({ canDisableEmails: false });

      expect(findEmailSettings().exists()).toBe(false);
    });
  });

  describe('Default award emojis', () => {
    it('should show the "Show default award emojis" input', () => {
      wrapper = mountComponent();

      expect(findShowDefaultAwardEmojis().exists()).toBe(true);
    });
  });

  describe('Warn about potentially unwanted characters', () => {
    it('should have a "Warn about Potentially Unwanted Characters" input', () => {
      wrapper = mountComponent();

      expect(findWarnAboutPuc().exists()).toBe(true);
    });
  });

  describe('Metrics dashboard', () => {
    it('should show the metrics dashboard access select', () => {
      wrapper = mountComponent();

      expect(findMetricsVisibilitySettings().exists()).toBe(true);
    });

    it('should contain help text', () => {
      wrapper = mountComponent();

      expect(findMetricsVisibilitySettings().props('helpText')).toBe(
        "Visualize the project's performance metrics.",
      );
    });

    it.each`
      before                                | after
      ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.EVERYONE}
      ${featureAccessLevel.NOT_ENABLED}     | ${featureAccessLevel.PROJECT_MEMBERS}
      ${featureAccessLevel.EVERYONE}        | ${featureAccessLevel.PROJECT_MEMBERS}
      ${featureAccessLevel.EVERYONE}        | ${featureAccessLevel.NOT_ENABLED}
      ${featureAccessLevel.PROJECT_MEMBERS} | ${featureAccessLevel.NOT_ENABLED}
    `(
      'when updating Operations Settings access level from `$before` to `$after`, Metric Dashboard access is updated to `$after` as well',
      async ({ before, after }) => {
        wrapper = mountComponent({
          currentSettings: { operationsAccessLevel: before, metricsDashboardAccessLevel: before },
        });

        await findOperationsVisibilityInput().vm.$emit('change', after);

        expect(findMetricsVisibilityInput().props('value')).toBe(after);
      },
    );

    it('when updating Operations Settings access level from `10` to `20`, Metric Dashboard access is not increased', async () => {
      wrapper = mountComponent({
        currentSettings: {
          operationsAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
          metricsDashboardAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
        },
      });

      await findOperationsVisibilityInput().vm.$emit('change', featureAccessLevel.EVERYONE);

      expect(findMetricsVisibilityInput().props('value')).toBe(featureAccessLevel.PROJECT_MEMBERS);
    });

    it('should reduce Metrics visibility level when visibility is set to private', async () => {
      wrapper = mountComponent({
        currentSettings: {
          visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
          operationsAccessLevel: featureAccessLevel.EVERYONE,
          metricsDashboardAccessLevel: featureAccessLevel.EVERYONE,
        },
      });

      await findProjectVisibilityLevelInput().setValue(VISIBILITY_LEVEL_PRIVATE_INTEGER);

      expect(findMetricsVisibilityInput().props('value')).toBe(featureAccessLevel.PROJECT_MEMBERS);
    });
  });

  describe('Analytics', () => {
    it('should show the analytics toggle', () => {
      wrapper = mountComponent();

      expect(findAnalyticsRow().exists()).toBe(true);
    });
  });

  describe('Operations', () => {
    it('should show the operations toggle', () => {
      wrapper = mountComponent();

      expect(findOperationsSettings().exists()).toBe(true);
    });
  });

  describe('Environments', () => {
    describe('with feature flag', () => {
      it('should show the environments toggle', () => {
        wrapper = mountComponent({
          glFeatures: { splitOperationsVisibilityPermissions: true },
        });

        expect(findEnvironmentsSettings().exists()).toBe(true);
      });
    });
    describe('without feature flag', () => {
      it('should not show the environments toggle', () => {
        wrapper = mountComponent({});

        expect(findEnvironmentsSettings().exists()).toBe(false);
      });
    });
  });
  describe('Feature Flags', () => {
    describe('with feature flag', () => {
      it('should show the feature flags toggle', () => {
        wrapper = mountComponent({
          glFeatures: { splitOperationsVisibilityPermissions: true },
        });

        expect(findFeatureFlagsSettings().exists()).toBe(true);
      });
    });
    describe('without feature flag', () => {
      it('should not show the feature flags toggle', () => {
        wrapper = mountComponent({});

        expect(findFeatureFlagsSettings().exists()).toBe(false);
      });
    });
  });
  describe('Releases', () => {
    describe('with feature flag', () => {
      it('should show the releases toggle', () => {
        wrapper = mountComponent({
          glFeatures: { splitOperationsVisibilityPermissions: true },
        });

        expect(findReleasesSettings().exists()).toBe(true);
      });
    });
    describe('without feature flag', () => {
      it('should not show the releases toggle', () => {
        wrapper = mountComponent({});

        expect(findReleasesSettings().exists()).toBe(false);
      });
    });
  });
  describe('Monitor', () => {
    const expectedAccessLevel = [
      [10, 'Only Project Members'],
      [20, 'Everyone With Access'],
    ];
    describe('with feature flag', () => {
      it('shows Monitor toggle instead of Operations toggle', () => {
        wrapper = mountComponent({
          glFeatures: { splitOperationsVisibilityPermissions: true },
        });

        expect(findMonitorSettings().exists()).toBe(true);
        expect(findOperationsSettings().exists()).toBe(false);
        expect(findMonitorSettings().findComponent(ProjectFeatureSetting).props('options')).toEqual(
          expectedAccessLevel,
        );
      });
      it('when monitorAccessLevel is for project members, it is also for everyone', () => {
        wrapper = mountComponent({
          glFeatures: { splitOperationsVisibilityPermissions: true },
          currentSettings: { monitorAccessLevel: featureAccessLevel.PROJECT_MEMBERS },
        });

        expect(findMetricsVisibilityInput().props('value')).toBe(featureAccessLevel.EVERYONE);
      });
    });
    describe('without feature flag', () => {
      it('shows Operations toggle instead of Monitor toggle', () => {
        wrapper = mountComponent({});

        expect(findMonitorSettings().exists()).toBe(false);
        expect(findOperationsSettings().exists()).toBe(true);
        expect(
          findOperationsSettings().findComponent(ProjectFeatureSetting).props('options'),
        ).toEqual(expectedAccessLevel);
      });
    });
  });
});
