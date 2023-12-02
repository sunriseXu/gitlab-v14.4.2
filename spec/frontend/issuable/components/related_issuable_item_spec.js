import { GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { formatDate } from '~/lib/utils/datetime_utility';
import { updateHistory } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import IssueAssignees from '~/issuable/components/issue_assignees.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { defaultAssignees, defaultMilestone } from './related_issuable_mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('RelatedIssuableItem', () => {
  let wrapper;

  const defaultProps = {
    idKey: 1,
    displayReference: 'gitlab-org/gitlab-test#1',
    pathIdSeparator: '#',
    path: `${TEST_HOST}/path`,
    title: 'title',
    confidential: true,
    dueDate: '1990-12-31',
    weight: 10,
    createdAt: '2018-12-01T00:00:00.00Z',
    milestone: defaultMilestone,
    assignees: defaultAssignees,
    eventNamespace: 'relatedIssue',
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findIssueDueDate = () => wrapper.findComponent(IssueDueDate);
  const findLockIcon = () => wrapper.find('[data-testid="lockIcon"]');
  const findRemoveButton = () => wrapper.findComponent(GlButton);
  const findTitleLink = () => wrapper.findComponent(GlLink);
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);

  function mountComponent({ data = {}, props = {} } = {}) {
    wrapper = shallowMount(RelatedIssuableItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return data;
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains issuable-info-container class when canReorder is false', () => {
    mountComponent({ props: { canReorder: false } });

    expect(wrapper.classes('issuable-info-container')).toBe(true);
  });

  it('does not render token state', () => {
    mountComponent();

    expect(wrapper.find('.text-secondary svg').exists()).toBe(false);
  });

  it('does not render remove button', () => {
    mountComponent();

    expect(findRemoveButton().exists()).toBe(false);
  });

  describe('token title', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('links to computedPath', () => {
      expect(findTitleLink().attributes('href')).toBe(defaultProps.path);
    });

    it('renders confidential icon', () => {
      expect(findIcon().attributes('title')).toBe(__('Confidential'));
    });

    it('renders title', () => {
      expect(findTitleLink().text()).toBe(defaultProps.title);
    });
  });

  describe('token state', () => {
    it('renders state title', () => {
      mountComponent({ props: { state: 'opened' } });
      const stateTitle = findIcon().attributes('title');
      const formattedCreateDate = formatDate(defaultProps.createdAt);

      expect(stateTitle).toContain('<span class="bold">Created</span>');
      expect(stateTitle).toContain(`<span class="text-tertiary">${formattedCreateDate}</span>`);
    });

    it('renders aria label', () => {
      mountComponent({ props: { state: 'opened' } });

      expect(findIcon().attributes('arialabel')).toBe('opened');
    });

    it('renders open icon when open state', () => {
      mountComponent({ props: { state: 'opened' } });

      expect(findIcon().props('name')).toBe('issue-open-m');
      expect(findIcon().classes('issue-token-state-icon-open')).toBe(true);
    });

    it('renders close icon when close state', () => {
      mountComponent({ props: { state: 'closed', closedAt: '2018-12-01T00:00:00.00Z' } });

      expect(findIcon().props('name')).toBe('issue-close');
      expect(findIcon().classes('issue-token-state-icon-closed')).toBe(true);
    });
  });

  describe('token metadata', () => {
    const tokenMetadata = () => wrapper.find('.item-meta');

    it('renders item path and ID', () => {
      mountComponent();
      const pathAndID = tokenMetadata().find('.item-path-id').text();

      expect(pathAndID).toContain('gitlab-org/gitlab-test');
      expect(pathAndID).toContain('#1');
    });

    it('renders milestone', () => {
      mountComponent();

      expect(wrapper.findComponent(IssueMilestone).props('milestone')).toEqual(
        defaultProps.milestone,
      );
    });

    it('renders due date component with correct due date', () => {
      mountComponent();

      expect(findIssueDueDate().props('date')).toBe(defaultProps.dueDate);
    });

    it('does not render red icon for overdue issue that is closed', () => {
      mountComponent({ props: { closedAt: '2018-12-01T00:00:00.00Z' } });

      expect(findIssueDueDate().props('closed')).toBe(true);
    });
  });

  describe('token assignees', () => {
    it('renders assignees avatars', () => {
      mountComponent();

      expect(wrapper.findComponent(IssueAssignees).props('assignees')).toEqual(
        defaultProps.assignees,
      );
    });
  });

  describe('remove button', () => {
    beforeEach(() => {
      mountComponent({ props: { canRemove: true }, data: { removeDisabled: true } });
    });

    it('renders if canRemove', () => {
      expect(findRemoveButton().props('icon')).toBe('close');
      expect(findRemoveButton().attributes('aria-label')).toBe(__('Remove'));
    });

    it('does not render the lock icon', () => {
      expect(findLockIcon().exists()).toBe(false);
    });

    it('renders disabled button when removeDisabled', () => {
      expect(findRemoveButton().attributes('disabled')).toBe('true');
    });

    it('triggers onRemoveRequest when clicked', () => {
      findRemoveButton().vm.$emit('click');

      expect(wrapper.emitted('relatedIssueRemoveRequest')).toEqual([[defaultProps.idKey]]);
    });
  });

  describe('when issue is locked', () => {
    const lockedMessage = 'Issues created from a vulnerability cannot be removed';

    beforeEach(() => {
      mountComponent({ props: { isLocked: true, lockedMessage } });
    });

    it('does not render the remove button', () => {
      expect(findRemoveButton().exists()).toBe(false);
    });

    it('renders the lock icon with the correct title', () => {
      expect(findLockIcon().attributes('title')).toBe(lockedMessage);
    });
  });

  describe('work item modal', () => {
    const workItem = 'gid://gitlab/WorkItem/1';

    it('renders', () => {
      mountComponent();

      expect(findWorkItemDetailModal().props('workItemId')).toBe(workItem);
    });

    describe('when work item is issue and the related issue title is clicked', () => {
      it('does not open', () => {
        mountComponent({ props: { workItemType: 'ISSUE' } });
        wrapper.vm.$refs.modal.show = jest.fn();

        findTitleLink().vm.$emit('click', { preventDefault: () => {} });

        expect(wrapper.vm.$refs.modal.show).not.toHaveBeenCalled();
      });
    });

    describe('when work item is task and the related issue title is clicked', () => {
      beforeEach(() => {
        mountComponent({ props: { workItemType: 'TASK' } });
        wrapper.vm.$refs.modal.show = jest.fn();
        findTitleLink().vm.$emit('click', { preventDefault: () => {} });
      });

      it('opens', () => {
        expect(wrapper.vm.$refs.modal.show).toHaveBeenCalled();
      });

      it('updates the url params with the work item id', () => {
        expect(updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?work_item_id=1`,
          replace: true,
        });
      });
    });

    describe('when it emits "workItemDeleted" event', () => {
      it('emits "relatedIssueRemoveRequest" event', () => {
        mountComponent();

        findWorkItemDetailModal().vm.$emit('workItemDeleted', workItem);

        expect(wrapper.emitted('relatedIssueRemoveRequest')).toEqual([[workItem]]);
      });
    });

    describe('when it emits "close" event', () => {
      it('removes the work item id from the url params', () => {
        mountComponent();

        findWorkItemDetailModal().vm.$emit('close');

        expect(updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/`,
          replace: true,
        });
      });
    });
  });
});
