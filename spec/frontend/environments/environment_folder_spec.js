import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubTransition } from 'helpers/stub_transition';
import { __, s__ } from '~/locale';
import EnvironmentsFolder from '~/environments/components/environment_folder.vue';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import { resolvedEnvironmentsApp, resolvedFolder } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/environments_folder.vue', () => {
  let wrapper;
  let environmentFolderMock;
  let intervalMock;
  let nestedEnvironment;

  const findLink = () => wrapper.findByRole('link', { name: s__('Environments|Show all') });

  const createApolloProvider = () => {
    const mockResolvers = { Query: { folder: environmentFolderMock, interval: intervalMock } };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (propsData, apolloProvider) =>
    mountExtended(EnvironmentsFolder, {
      apolloProvider,
      propsData: {
        scope: 'available',
        ...propsData,
      },
      stubs: { transition: stubTransition() },
      provide: { helpPagePath: '/help' },
    });

  beforeEach(async () => {
    environmentFolderMock = jest.fn();
    [nestedEnvironment] = resolvedEnvironmentsApp.environments;
    environmentFolderMock.mockReturnValue(resolvedFolder);
    intervalMock = jest.fn();
    intervalMock.mockReturnValue(2000);
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('default', () => {
    let folderName;
    let button;

    beforeEach(async () => {
      wrapper = createWrapper({ nestedEnvironment }, createApolloProvider());

      await nextTick();
      await waitForPromises();
      folderName = wrapper.findByText(nestedEnvironment.name);
      button = wrapper.findByRole('button', { name: __('Expand') });
    });

    it('displays the name of the folder', () => {
      expect(folderName.text()).toBe(nestedEnvironment.name);
    });

    describe('collapse', () => {
      let icons;
      let collapse;

      beforeEach(() => {
        collapse = wrapper.findComponent(GlCollapse);
        icons = wrapper.findAllComponents(GlIcon);
        jest.spyOn(wrapper.vm.$apollo.queries.folder, 'startPolling');
        jest.spyOn(wrapper.vm.$apollo.queries.folder, 'stopPolling');
      });

      it('is collapsed by default', () => {
        const link = findLink();

        expect(collapse.attributes('visible')).toBeUndefined();
        const iconNames = icons.wrappers.map((i) => i.props('name')).slice(0, 2);
        expect(iconNames).toEqual(['chevron-lg-right', 'folder-o']);
        expect(folderName.classes('gl-font-weight-bold')).toBe(false);
        expect(link.exists()).toBe(false);
      });

      it('opens on click', async () => {
        await button.trigger('click');

        const link = findLink();

        expect(button.attributes('aria-label')).toBe(__('Collapse'));
        expect(collapse.attributes('visible')).toBe('visible');
        const iconNames = icons.wrappers.map((i) => i.props('name')).slice(0, 2);
        expect(iconNames).toEqual(['chevron-lg-down', 'folder-open']);
        expect(folderName.classes('gl-font-weight-bold')).toBe(true);
        expect(link.attributes('href')).toBe(nestedEnvironment.latest.folderPath);

        expect(wrapper.vm.$apollo.queries.folder.startPolling).toHaveBeenCalledWith(2000);
      });

      it('displays all environments when opened', async () => {
        await button.trigger('click');

        const names = resolvedFolder.environments.map((e) =>
          expect.stringMatching(e.nameWithoutType),
        );
        const environments = wrapper
          .findAllComponents(EnvironmentItem)
          .wrappers.map((w) => w.text());
        expect(environments).toEqual(expect.arrayContaining(names));
      });

      it('stops polling on click', async () => {
        await button.trigger('click');
        expect(wrapper.vm.$apollo.queries.folder.startPolling).toHaveBeenCalledWith(2000);

        const collapseButton = wrapper.findByRole('button', { name: __('Collapse') });
        await collapseButton.trigger('click');

        expect(wrapper.vm.$apollo.queries.folder.stopPolling).toHaveBeenCalled();
      });
    });
  });

  it.each(['available', 'stopped'])(
    'with scope=%s, fetches environments with scope',
    async (scope) => {
      wrapper = createWrapper({ nestedEnvironment, scope }, createApolloProvider());

      await nextTick();
      await waitForPromises();

      expect(environmentFolderMock).toHaveBeenCalledTimes(1);
      expect(environmentFolderMock).toHaveBeenCalledWith(
        {},
        {
          environment: nestedEnvironment.latest,
          scope,
        },
        expect.anything(),
        expect.anything(),
      );
    },
  );
});
