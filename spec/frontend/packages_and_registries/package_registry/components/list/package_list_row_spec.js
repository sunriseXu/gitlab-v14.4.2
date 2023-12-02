import { GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagePath from '~/packages_and_registries/shared/components/package_path.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PackageIconAndName from '~/packages_and_registries/shared/components/package_icon_and_name.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { PACKAGE_ERROR_STATUS } from '~/packages_and_registries/package_registry/constants';

import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { packageData, packagePipelines, packageProject, packageTags } from '../../mock_data';

Vue.use(VueRouter);

describe('packages_list_row', () => {
  let wrapper;

  const defaultProvide = {
    isGroupPage: false,
  };

  const packageWithoutTags = { ...packageData(), project: packageProject() };
  const packageWithTags = { ...packageWithoutTags, tags: { nodes: packageTags() } };
  const packageCannotDestroy = { ...packageData(), canDestroy: false };

  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findPackagePath = () => wrapper.findComponent(PackagePath);
  const findDeleteDropdown = () => wrapper.findByTestId('action-delete');
  const findPackageIconAndName = () => wrapper.findComponent(PackageIconAndName);
  const findPackageLink = () => wrapper.findByTestId('details-link');
  const findWarningIcon = () => wrapper.findByTestId('warning-icon');
  const findLeftSecondaryInfos = () => wrapper.findByTestId('left-secondary-infos');
  const findPublishMethod = () => wrapper.findComponent(PublishMethod);
  const findCreatedDateText = () => wrapper.findByTestId('created-date');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeagoTooltip);

  const mountComponent = ({
    packageEntity = packageWithoutTags,
    provide = defaultProvide,
  } = {}) => {
    wrapper = shallowMountExtended(PackagesListRow, {
      provide,
      stubs: {
        ListItem,
        GlSprintf,
      },
      propsData: {
        packageEntity,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a link to navigate to the details page', () => {
    mountComponent();

    expect(findPackageLink().props()).toMatchObject({
      event: 'click',
      to: { name: 'details', params: { id: getIdFromGraphQLId(packageWithoutTags.id) } },
    });
  });

  describe('tags', () => {
    it('renders package tags when a package has tags', () => {
      mountComponent({ packageEntity: packageWithTags });

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not render when there are no tags', () => {
      mountComponent();

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('when it is group', () => {
    it('has a package path component', () => {
      mountComponent({ provide: { isGroupPage: true } });

      expect(findPackagePath().exists()).toBe(true);
      expect(findPackagePath().props()).toMatchObject({ path: 'gitlab-org/gitlab-test' });
    });
  });

  describe('delete button', () => {
    it('does not exist when package cannot be destroyed', () => {
      mountComponent({ packageEntity: packageCannotDestroy });

      expect(findDeleteDropdown().exists()).toBe(false);
    });

    it('exists and has the correct props', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      expect(findDeleteDropdown().exists()).toBe(true);
      expect(findDeleteDropdown().attributes()).toMatchObject({
        variant: 'danger',
      });
    });

    it('emits the packageToDelete event when the delete button is clicked', async () => {
      mountComponent({ packageEntity: packageWithoutTags });

      findDeleteDropdown().vm.$emit('click');

      await nextTick();
      expect(wrapper.emitted('packageToDelete')).toHaveLength(1);
      expect(wrapper.emitted('packageToDelete')[0]).toEqual([packageWithoutTags]);
    });
  });

  describe(`when the package is in ${PACKAGE_ERROR_STATUS} status`, () => {
    beforeEach(() => {
      mountComponent({ packageEntity: { ...packageWithoutTags, status: PACKAGE_ERROR_STATUS } });
    });

    it('details link is disabled', () => {
      expect(findPackageLink().props('event')).toBe('');
    });

    it('has a warning icon', () => {
      const icon = findWarningIcon();
      const tooltip = getBinding(icon.element, 'gl-tooltip');
      expect(icon.props('name')).toBe('warning');
      expect(tooltip.value).toMatchObject({
        title: 'Invalid Package: failed metadata extraction',
      });
    });

    it('has a delete dropdown', () => {
      expect(findDeleteDropdown().exists()).toBe(true);
    });
  });

  describe('secondary left info', () => {
    it('has the package version', () => {
      mountComponent();

      expect(findLeftSecondaryInfos().text()).toContain(packageWithoutTags.version);
    });

    it('if the pipeline exists show the author message', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findLeftSecondaryInfos().text()).toContain('published by Administrator');
    });

    it('has icon and name component', () => {
      mountComponent();

      expect(findPackageIconAndName().text()).toBe(packageWithoutTags.packageType.toLowerCase());
    });
  });

  describe('right info', () => {
    it('has publish method component', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findPublishMethod().props('pipeline')).toEqual(packagePipelines()[0]);
    });

    it('has the created date', () => {
      mountComponent();

      expect(findCreatedDateText().text()).toMatchInterpolatedText(PackagesListRow.i18n.createdAt);
      expect(findTimeAgoTooltip().props()).toMatchObject({
        time: packageData().createdAt,
      });
    });
  });
});
