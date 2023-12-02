import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { IssuableType } from '~/issues/constants';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';

const user = {
  name: 'John Doe',
  username: 'johndoe',
  webUrl: '/link',
  avatarUrl: '/avatar',
};

describe('Sidebar participant component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = ({
    status = null,
    issuableType = IssuableType.Issue,
    canMerge = false,
  } = {}) => {
    wrapper = shallowMount(SidebarParticipant, {
      propsData: {
        user: {
          ...user,
          canMerge,
          status,
        },
        issuableType,
      },
      stubs: {
        GlAvatarLabeled,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not show `Busy` status when user is not busy', () => {
    createComponent();

    expect(findAvatar().props('label')).toBe(user.name);
  });

  it('shows `Busy` status when user is busy', () => {
    createComponent({ status: { availability: 'BUSY' } });

    expect(findAvatar().props('label')).toBe(`${user.name} (Busy)`);
  });

  it('does not render a warning icon', () => {
    createComponent();

    expect(findIcon().exists()).toBe(false);
  });

  describe('when on merge request sidebar', () => {
    it('when project member cannot merge', () => {
      createComponent({ issuableType: IssuableType.MergeRequest });

      expect(findIcon().exists()).toBe(true);
    });

    it('when project member can merge', () => {
      createComponent({ issuableType: IssuableType.MergeRequest, canMerge: true });

      expect(findIcon().exists()).toBe(false);
    });
  });
});
