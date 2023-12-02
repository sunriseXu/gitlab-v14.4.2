import { GlBadge, GlIcon, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

const issuableHeaderProps = {
  ...mockIssuable,
  ...mockIssuableShowProps,
};

describe('IssuableHeader', () => {
  let wrapper;

  const findTaskStatusEl = () => wrapper.findByTestId('task-status');

  const createComponent = (props = {}, { stubs } = {}) => {
    wrapper = shallowMountExtended(IssuableHeader, {
      propsData: {
        ...issuableHeaderProps,
        ...props,
      },
      slots: {
        'status-badge': 'Open',
        'header-actions': `
        <button class="js-close">Close issuable</button>
        <a class="js-new" href="/gitlab-org/gitlab-shell/-/issues/new">New issuable</a>
      `,
      },
      stubs,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    resetHTMLFixture();
  });

  describe('computed', () => {
    describe('authorId', () => {
      it('returns numeric ID from GraphQL ID of `author` prop', () => {
        createComponent();
        expect(wrapper.vm.authorId).toBe(1);
      });
    });
  });

  describe('handleRightSidebarToggleClick', () => {
    beforeEach(() => {
      setHTMLFixture('<button class="js-toggle-right-sidebar-button">Collapse sidebar</button>');
    });

    it('dispatches `click` event on sidebar toggle button', () => {
      createComponent();
      wrapper.vm.toggleSidebarButtonEl = document.querySelector('.js-toggle-right-sidebar-button');
      jest.spyOn(wrapper.vm.toggleSidebarButtonEl, 'dispatchEvent').mockImplementation(jest.fn);

      wrapper.vm.handleRightSidebarToggleClick();

      expect(wrapper.vm.toggleSidebarButtonEl.dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'click',
        }),
      );
    });
  });

  describe('template', () => {
    it('renders issuable status icon and text', () => {
      createComponent();
      const statusBoxEl = wrapper.findComponent(GlBadge);
      const statusIconEl = statusBoxEl.findComponent(GlIcon);

      expect(statusBoxEl.exists()).toBe(true);
      expect(statusIconEl.props('name')).toBe(mockIssuableShowProps.statusIcon);
      expect(statusIconEl.attributes('class')).toBe(mockIssuableShowProps.statusIconClass);
      expect(statusBoxEl.text()).toContain('Open');
    });

    it('renders blocked icon when issuable is blocked', async () => {
      createComponent({
        blocked: true,
      });

      const blockedEl = wrapper.findByTestId('blocked');

      expect(blockedEl.exists()).toBe(true);
      expect(blockedEl.findComponent(GlIcon).props('name')).toBe('lock');
    });

    it('renders confidential icon when issuable is confidential', async () => {
      createComponent({
        confidential: true,
      });

      const confidentialEl = wrapper.findByTestId('confidential');

      expect(confidentialEl.exists()).toBe(true);
      expect(confidentialEl.findComponent(GlIcon).props('name')).toBe('eye-slash');
    });

    it('renders issuable author avatar', () => {
      createComponent();
      const { username, name, webUrl, avatarUrl } = mockIssuable.author;
      const avatarElAttrs = {
        'data-user-id': '1',
        'data-username': username,
        'data-name': name,
        href: webUrl,
        target: '_blank',
      };
      const avatarEl = wrapper.findByTestId('avatar');
      expect(avatarEl.exists()).toBe(true);
      expect(avatarEl.attributes()).toMatchObject(avatarElAttrs);
      expect(avatarEl.findComponent(GlAvatarLabeled).attributes()).toMatchObject({
        size: '24',
        src: avatarUrl,
        label: name,
      });
      expect(avatarEl.findComponent(GlAvatarLabeled).findComponent(GlIcon).exists()).toBe(false);
    });

    it('renders task status text when `taskCompletionStatus` prop is defined', () => {
      createComponent();

      expect(findTaskStatusEl().exists()).toBe(true);
      expect(findTaskStatusEl().text()).toContain('0 of 5 checklist items completed');
    });

    it('does not render task status text when tasks count is 0', () => {
      createComponent({
        taskCompletionStatus: {
          count: 0,
          completedCount: 0,
        },
      });

      expect(findTaskStatusEl().exists()).toBe(false);
    });

    it('renders sidebar toggle button', () => {
      createComponent();
      const toggleButtonEl = wrapper.findByTestId('sidebar-toggle');

      expect(toggleButtonEl.exists()).toBe(true);
      expect(toggleButtonEl.props('icon')).toBe('chevron-double-lg-left');
    });

    it('renders header actions', () => {
      createComponent();
      const actionsEl = wrapper.findByTestId('header-actions');

      expect(actionsEl.find('button.js-close').exists()).toBe(true);
      expect(actionsEl.find('a.js-new').exists()).toBe(true);
    });

    describe('when author exists outside of GitLab', () => {
      it("renders 'external-link' icon in avatar label", () => {
        createComponent(
          {
            author: {
              ...issuableHeaderProps.author,
              webUrl: 'https://jira.com/test-user/author.jpg',
            },
          },
          {
            stubs: {
              GlAvatarLabeled,
            },
          },
        );

        const avatarEl = wrapper.findComponent(GlAvatarLabeled);
        const icon = avatarEl.findComponent(GlIcon);

        expect(icon.exists()).toBe(true);
        expect(icon.props('name')).toBe('external-link');
      });
    });
  });
});
