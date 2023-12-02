import { GlAlert, GlBadge, GlLoadingIcon, GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import workItemWeightSubscription from 'ee_component/work_items/graphql/work_item_weight.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemInformation from '~/work_items/components/work_item_information.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemDatesSubscription from '~/work_items/graphql/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '~/work_items/graphql/update_work_item_task.mutation.graphql';
import { temporaryConfig } from '~/graphql_shared/issuable_client';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import {
  mockParent,
  workItemDatesSubscriptionResponse,
  workItemResponseFactory,
  workItemTitleSubscriptionResponse,
  workItemWeightSubscriptionResponse,
} from '../mock_data';

describe('WorkItemDetail component', () => {
  let wrapper;
  useLocalStorageSpy();

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryResponseWithoutParent = workItemResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const weightSubscriptionHandler = jest.fn().mockResolvedValue(workItemWeightSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findWorkItemState = () => wrapper.findComponent(WorkItemState);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDate);
  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findParent = () => wrapper.find('[data-testid="work-item-parent"]');
  const findParentButton = () => findParent().findComponent(GlButton);
  const findCloseButton = () => wrapper.find('[data-testid="work-item-close"]');
  const findWorkItemType = () => wrapper.find('[data-testid="work-item-type"]');
  const findWorkItemInformationAlert = () => wrapper.findComponent(WorkItemInformation);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const createComponent = ({
    isModal = false,
    updateInProgress = false,
    workItemId = workItemQueryResponse.data.workItem.id,
    handler = successHandler,
    subscriptionHandler = titleSubscriptionHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
    workItemsMvc2Enabled = false,
    includeWidgets = false,
    error = undefined,
  } = {}) => {
    const handlers = [
      [workItemQuery, handler],
      [workItemTitleSubscription, subscriptionHandler],
      [workItemDatesSubscription, datesSubscriptionHandler],
      confidentialityMock,
    ];

    if (IS_EE) {
      handlers.push([workItemWeightSubscription, weightSubscriptionHandler]);
    }

    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo(
        handlers,
        {},
        {
          typePolicies: includeWidgets ? temporaryConfig.cacheConfig.typePolicies : {},
        },
      ),
      propsData: { isModal, workItemId },
      data() {
        return {
          updateInProgress,
          error,
        };
      },
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
        },
        hasIssueWeightsFeature: true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there is no `workItemId` prop', () => {
    beforeEach(() => {
      createComponent({ workItemId: null });
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton loader', () => {
      expect(findSkeleton().exists()).toBe(true);
      expect(findWorkItemState().exists()).toBe(false);
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render skeleton', () => {
      expect(findSkeleton().exists()).toBe(false);
      expect(findWorkItemState().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(true);
    });

    it('updates the document title', () => {
      expect(document.title).toEqual('Updated title · Task · test-project-path');
    });
  });

  describe('close button', () => {
    describe('when isModal prop is false', () => {
      it('does not render', async () => {
        createComponent({ isModal: false });
        await waitForPromises();

        expect(findCloseButton().exists()).toBe(false);
      });
    });

    describe('when isModal prop is true', () => {
      it('renders', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        expect(findCloseButton().props('icon')).toBe('close');
        expect(findCloseButton().attributes('aria-label')).toBe('Close');
      });

      it('emits `close` event when clicked', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        findCloseButton().vm.$emit('click');

        expect(wrapper.emitted('close')).toEqual([[]]);
      });
    });
  });

  describe('confidentiality', () => {
    const errorMessage = 'Mutation failed';
    const confidentialWorkItem = workItemResponseFactory({
      confidential: true,
    });

    // Mocks for work item without parent
    const withoutParentExpectedInputVars = {
      id: workItemQueryResponse.data.workItem.id,
      confidential: true,
    };
    const toggleConfidentialityWithoutParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: confidentialWorkItem.data.workItem,
          errors: [],
        },
      },
    });
    const withoutParentHandlerMock = jest
      .fn()
      .mockResolvedValue(workItemQueryResponseWithoutParent);
    const confidentialityWithoutParentMock = [
      updateWorkItemMutation,
      toggleConfidentialityWithoutParentHandler,
    ];
    const confidentialityWithoutParentFailureMock = [
      updateWorkItemMutation,
      jest.fn().mockRejectedValue(new Error(errorMessage)),
    ];

    // Mocks for work item with parent
    const withParentExpectedInputVars = {
      id: mockParent.parent.id,
      taskData: { id: workItemQueryResponse.data.workItem.id, confidential: true },
    };
    const toggleConfidentialityWithParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: {
            id: confidentialWorkItem.data.workItem.id,
            descriptionHtml: confidentialWorkItem.data.workItem.description,
          },
          task: {
            workItem: confidentialWorkItem.data.workItem,
            confidential: true,
          },
          errors: [],
        },
      },
    });
    const confidentialityWithParentMock = [
      updateWorkItemTaskMutation,
      toggleConfidentialityWithParentHandler,
    ];
    const confidentialityWithParentFailureMock = [
      updateWorkItemTaskMutation,
      jest.fn().mockRejectedValue(new Error(errorMessage)),
    ];

    describe.each`
      context        | handlerMock                 | confidentialityMock                 | confidentialityFailureMock                 | inputVariables
      ${'no parent'} | ${withoutParentHandlerMock} | ${confidentialityWithoutParentMock} | ${confidentialityWithoutParentFailureMock} | ${withoutParentExpectedInputVars}
      ${'parent'}    | ${successHandler}           | ${confidentialityWithParentMock}    | ${confidentialityWithParentFailureMock}    | ${withParentExpectedInputVars}
    `(
      'when work item has $context',
      ({ handlerMock, confidentialityMock, confidentialityFailureMock, inputVariables }) => {
        it('renders confidential badge when work item is confidential', async () => {
          createComponent({
            handler: jest.fn().mockResolvedValue(confidentialWorkItem),
            confidentialityMock,
          });

          await waitForPromises();

          const confidentialBadge = wrapper.findComponent(GlBadge);
          expect(confidentialBadge.exists()).toBe(true);
          expect(confidentialBadge.props()).toMatchObject({
            variant: 'warning',
            icon: 'eye-slash',
          });
          expect(confidentialBadge.attributes('title')).toBe(
            'Only project members with at least the Reporter role, the author, and assignees can view or be notified about this task.',
          );
          expect(confidentialBadge.text()).toBe('Confidential');
        });

        it('renders gl-loading-icon while update mutation is in progress', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock,
          });

          await waitForPromises();

          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);

          await nextTick();

          expect(findLoadingIcon().exists()).toBe(true);
        });

        it('emits workItemUpdated and shows confidentiality badge when mutation is successful', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock,
          });

          await waitForPromises();

          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
          await waitForPromises();

          expect(wrapper.emitted('workItemUpdated')).toEqual([[{ confidential: true }]]);
          expect(confidentialityMock[1]).toHaveBeenCalledWith({
            input: inputVariables,
          });
          expect(findLoadingIcon().exists()).toBe(false);
        });

        it('shows alert message when mutation fails', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock: confidentialityFailureMock,
          });

          await waitForPromises();
          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
          await waitForPromises();
          expect(wrapper.emitted('workItemUpdated')).toBeUndefined();

          await nextTick();

          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(errorMessage);
          expect(findLoadingIcon().exists()).toBe(false);
        });
      },
    );
  });

  describe('description', () => {
    it('does not show description widget if loading description fails', () => {
      createComponent();

      expect(findWorkItemDescription().exists()).toBe(false);
    });

    it('shows description widget if description loads', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemDescription().exists()).toBe(true);
    });
  });

  describe('secondary breadcrumbs', () => {
    it('does not show secondary breadcrumbs by default', () => {
      createComponent();

      expect(findParent().exists()).toBe(false);
    });

    it('does not show secondary breadcrumbs if there is not a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();

      expect(findParent().exists()).toBe(false);
    });

    it('shows work item type if there is not a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().exists()).toBe(true);
    });

    describe('with parent', () => {
      beforeEach(() => {
        const parentResponse = workItemResponseFactory(mockParent);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });

        return waitForPromises();
      });

      it('shows secondary breadcrumbs if there is a parent', () => {
        expect(findParent().exists()).toBe(true);
      });

      it('does not show work item type', async () => {
        expect(findWorkItemType().exists()).toBe(false);
      });

      it('sets the parent breadcrumb URL', () => {
        expect(findParentButton().attributes().href).toBe('../../issues/5');
      });
    });
  });

  it('shows an error message when the work item query was unsuccessful', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });
    await waitForPromises();

    expect(errorHandler).toHaveBeenCalled();
    expect(findAlert().text()).toBe(i18n.fetchError);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await waitForPromises();
    const updateError = 'Failed to update';

    findWorkItemTitle().vm.$emit('error', updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(updateError);
  });

  describe('subscriptions', () => {
    it('calls the title subscription', () => {
      createComponent();

      expect(titleSubscriptionHandler).toHaveBeenCalledWith({
        issuableId: workItemQueryResponse.data.workItem.id,
      });
    });

    describe('dates subscription', () => {
      describe('when the due date widget exists', () => {
        it('calls the dates subscription', async () => {
          createComponent();
          await waitForPromises();

          expect(datesSubscriptionHandler).toHaveBeenCalledWith({
            issuableId: workItemQueryResponse.data.workItem.id,
          });
        });
      });

      describe('when the due date widget does not exist', () => {
        it('does not call the dates subscription', async () => {
          const response = workItemResponseFactory({ datesWidgetPresent: false });
          const handler = jest.fn().mockResolvedValue(response);
          createComponent({ handler, workItemsMvc2Enabled: true });
          await waitForPromises();

          expect(datesSubscriptionHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('assignees widget', () => {
    it('renders assignees component when widget is returned from the API', async () => {
      createComponent({
        workItemsMvc2Enabled: true,
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(true);
    });

    it('does not render assignees component when widget is not returned from the API', async () => {
      createComponent({
        workItemsMvc2Enabled: true,
        handler: jest
          .fn()
          .mockResolvedValue(workItemResponseFactory({ assigneesWidgetPresent: false })),
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(false);
    });
  });

  describe('labels widget', () => {
    it.each`
      description                                               | includeWidgets | exists
      ${'renders when widget is returned from API'}             | ${true}        | ${true}
      ${'does not render when widget is not returned from API'} | ${false}       | ${false}
    `('$description', async ({ includeWidgets, exists }) => {
      createComponent({ includeWidgets, workItemsMvc2Enabled: true });
      await waitForPromises();

      expect(findWorkItemLabels().exists()).toBe(exists);
    });
  });

  describe('dates widget', () => {
    describe.each`
      description                               | datesWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}            | ${true}
      ${'when widget is not returned from API'} | ${false}           | ${false}
    `('$description', ({ datesWidgetPresent, exists }) => {
      it(`${datesWidgetPresent ? 'renders' : 'does not render'} due date component`, async () => {
        const response = workItemResponseFactory({ datesWidgetPresent });
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler, workItemsMvc2Enabled: true });
        await waitForPromises();

        expect(findWorkItemDueDate().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent({ workItemsMvc2Enabled: true });
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemDueDate().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });

  describe('work item information', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('is visible when viewed for the first time and sets localStorage value', async () => {
      localStorage.clear();
      expect(findWorkItemInformationAlert().exists()).toBe(true);
      expect(findLocalStorageSync().props('value')).toBe(true);
    });

    it('is not visible after reading local storage input', async () => {
      await findLocalStorageSync().vm.$emit('input', false);
      expect(findWorkItemInformationAlert().exists()).toBe(false);
    });
  });
});
