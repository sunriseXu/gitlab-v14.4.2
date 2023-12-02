import { GlAlert, GlButton, GlLoadingIcon, GlLabel, GlTableLite } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';

import Table from 'ee/groups/settings/compliance_frameworks/components/table.vue';
import EmptyState from 'ee/groups/settings/compliance_frameworks/components/table_empty_state.vue';
import TableActions from 'ee/groups/settings/compliance_frameworks/components/table_actions.vue';
import DeleteModal from 'ee/groups/settings/compliance_frameworks/components/delete_modal.vue';
import { PIPELINE_CONFIGURATION_PATH_FORMAT } from 'ee/groups/settings/compliance_frameworks/constants';
import getComplianceFrameworkQuery from 'ee/groups/settings/compliance_frameworks/graphql/queries/get_compliance_framework.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { validFetchResponse, emptyFetchResponse } from '../mock_data';

Vue.use(VueApollo);

describe('Table', () => {
  let wrapper;
  const sentryError = new Error('Network error');

  const fetch = jest.fn().mockResolvedValue(validFetchResponse);
  const fetchEmpty = jest.fn().mockResolvedValue(emptyFetchResponse);
  const fetchLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const fetchWithErrors = jest.fn().mockRejectedValue(sentryError);

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findDescriptions = () => wrapper.findAllByTestId('compliance-framework-description');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findAddBtn = () => wrapper.findComponent(GlButton);
  const findAllTableActions = () => wrapper.findAllComponents(TableActions);

  function createMockApolloProvider(resolverMock) {
    Vue.use(VueApollo);

    const requestHandlers = [[getComplianceFrameworkQuery, resolverMock]];

    return createMockApollo(requestHandlers);
  }

  function createComponentWithApollo(resolverMock, props = {}, mountFn = shallowMount) {
    return extendedWrapper(
      mountFn(Table, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          addFrameworkPath: 'group/framework/new',
          editFrameworkPath: 'group/framework/id/edit',
          emptyStateSvgPath: 'dir/image.svg',
          groupPath: 'group-1',
          ...props,
        },
        stubs: {
          GlLoadingIcon,
        },
      }),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(fetchLoading);
    });

    it('shows the loader', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
      expect(findAddBtn().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('fetching error', () => {
    beforeEach(async () => {
      wrapper = createComponentWithApollo(fetchWithErrors);
      jest.spyOn(Sentry, 'captureException');
      await waitForPromises();
    });

    it('shows the alert', () => {
      expect(findAlert().props('dismissible')).toBe(false);
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toBe(
        'Error fetching compliance frameworks data. Please refresh the page',
      );
    });

    it('does not show the other parts of the app', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
      expect(findAddBtn().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should fetch data once', () => {
      expect(fetchWithErrors).toHaveBeenCalledTimes(1);
    });

    it('sends the error to Sentry', async () => {
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('empty state', () => {
    beforeEach(async () => {
      wrapper = createComponentWithApollo(fetchEmpty);
      await waitForPromises();
    });

    it('shows the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('imagePath')).toBe('dir/image.svg');
      expect(findEmptyState().props('addFrameworkPath')).toBe('group/framework/new');
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
      expect(findAddBtn().exists()).toBe(false);
      expect(findDeleteModal().exists()).toBe(false);
    });
  });

  describe('content', () => {
    beforeEach(async () => {
      wrapper = createComponentWithApollo(fetch);
      await waitForPromises();
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('shows the add framework button', () => {
      const addBtn = findAddBtn();

      expect(addBtn.attributes('href')).toBe('group/framework/new');
      expect(addBtn.text()).toBe('Add framework');
    });

    it('renders the delete modal', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });

    describe('when no paths are provided', () => {
      beforeEach(() => {
        wrapper = createComponentWithApollo(fetch, {
          addFrameworkPath: null,
          editFrameworkPath: null,
        });
      });

      it('does not show the add framework button', () => {
        expect(findAddBtn().exists()).toBe(false);
      });
    });
  });

  describe('table content', () => {
    beforeEach(async () => {
      wrapper = createComponentWithApollo(fetch, {}, mount);
      await waitForPromises();
    });

    it('shows the table items with expect props', () => {
      expect(findAllTableActions()).toHaveLength(2);
      findAllTableActions().wrappers.forEach((item) =>
        expect(item.props()).toStrictEqual(
          expect.objectContaining({
            framework: {
              __typename: 'ComplianceFramework',
              id: expect.stringContaining('gid://gitlab/ComplianceManagement::Framework/'),
              parsedId: expect.any(Number),
              name: expect.any(String),
              description: expect.any(String),
              pipelineConfigurationFullPath: expect.stringMatching(
                PIPELINE_CONFIGURATION_PATH_FORMAT,
              ),
              color: expect.stringMatching(/^#([0-9A-F]{3}){1,2}$/i),
              editPath: expect.stringMatching(/^group\/framework\/[0-9+]\/edit$/i),
            },
            loading: false,
          }),
        ),
      );
    });

    it('displays the description defined by the 1st framework mock data', () => {
      expect(findDescriptions().at(0).text()).toBe('General Data Protection Regulation');
    });

    it('displays the label', () => {
      expect(findLabels().at(0).props()).toMatchObject({
        title: 'GDPR',
        backgroundColor: '#1aaa55',
        target: 'group/framework/1/edit',
        disabled: false,
        description: 'Edit framework',
      });
    });
  });

  describe('delete framework', () => {
    describe('when an item is marked for deletion', () => {
      let framework;
      const findTableAction = () => findAllTableActions().at(0);

      beforeEach(async () => {
        wrapper = createComponentWithApollo(fetch, {}, mount);

        await waitForPromises();

        framework = findTableAction().props('framework');
        findDeleteModal().vm.show = jest.fn();
        findTableAction().vm.$emit('delete', framework);
      });

      it('shows the modal when there is a "delete" event from a table item', () => {
        expect(findDeleteModal().props('id')).toBe(framework.id);
        expect(findDeleteModal().props('name')).toBe(framework.name);
        expect(findDeleteModal().vm.show).toHaveBeenCalled();
      });

      describe('and multiple items are being deleted', () => {
        beforeEach(() => {
          findAllTableActions().wrappers.forEach((tableAction) => {
            tableAction.vm.$emit('delete', tableAction.props('framework'));
            findDeleteModal().vm.$emit('deleting');
          });
        });

        it('sets "loading" to true on the deleting table items', () => {
          expect(
            findAllTableActions().wrappers.every((tableAction) => tableAction.props('loading')),
          ).toBe(true);
        });

        describe('and an error occurred', () => {
          beforeEach(() => {
            findDeleteModal().vm.$emit('error');
          });

          it('shows the alert for the error', () => {
            expect(findAlert().props('dismissible')).toBe(false);
            expect(findAlert().props('variant')).toBe('danger');
            expect(findAlert().text()).toBe(
              'Error deleting the compliance framework. Please try again',
            );
          });
        });

        describe('and the item was successfully deleted', () => {
          beforeEach(async () => {
            findDeleteModal().vm.$emit('delete', framework.id);
            await waitForPromises();
          });

          it('sets "loading" to false on the deleted table item', () => {
            expect(findTableAction().props('loading')).toBe(false);
          });

          it('shows the alert for the success message', () => {
            expect(findAlert().props('dismissible')).toBe(true);
            expect(findAlert().props('variant')).toBe('info');
            expect(findAlert().text()).toBe('Compliance framework deleted successfully');
          });

          it('can dismiss the alert message', async () => {
            findAlert().vm.$emit('dismiss');

            await nextTick();

            expect(findAlert().exists()).toBe(false);
          });
        });
      });
    });
  });
});
