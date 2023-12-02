import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link_old.vue';

describe('User Avatar Link Component', () => {
  let wrapper;

  const findUserName = () => wrapper.find('[data-testid="user-avatar-link-username"]');

  const defaultProps = {
    linkHref: `${TEST_HOST}/myavatarurl.com`,
    imgSize: 32,
    imgSrc: `${TEST_HOST}/myavatarurl.com`,
    imgAlt: 'mydisplayname',
    imgCssClasses: 'myextraavatarclass',
    tooltipText: 'tooltip text',
    tooltipPlacement: 'bottom',
    username: 'username',
  };

  const createWrapper = (props, slots) => {
    wrapper = shallowMountExtended(UserAvatarLink, {
      propsData: {
        ...defaultProps,
        ...props,
        ...slots,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render GlLink with correct props', () => {
    const link = wrapper.findComponent(GlLink);
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(defaultProps.linkHref);
  });

  it('should render UserAvatarImage and povide correct props to it', () => {
    expect(wrapper.findComponent(UserAvatarImage).exists()).toBe(true);
    expect(wrapper.findComponent(UserAvatarImage).props()).toEqual({
      cssClasses: defaultProps.imgCssClasses,
      imgAlt: defaultProps.imgAlt,
      imgSrc: defaultProps.imgSrc,
      lazy: false,
      size: defaultProps.imgSize,
      tooltipPlacement: defaultProps.tooltipPlacement,
      tooltipText: '',
      enforceGlAvatar: false,
    });
  });

  describe('when username provided', () => {
    beforeEach(() => {
      createWrapper({ username: defaultProps.username });
    });

    it('should render provided username', () => {
      expect(findUserName().text()).toBe(defaultProps.username);
    });

    it('should provide the tooltip data for the username', () => {
      expect(findUserName().attributes()).toEqual(
        expect.objectContaining({
          title: defaultProps.tooltipText,
          'tooltip-placement': defaultProps.tooltipPlacement,
        }),
      );
    });
  });

  describe('when username is NOT provided', () => {
    beforeEach(() => {
      createWrapper({ username: '' });
    });

    it('should NOT render username', () => {
      expect(findUserName().exists()).toBe(false);
    });
  });

  describe('avatar-badge slot', () => {
    const badge = '<span>User badge</span>';

    beforeEach(() => {
      createWrapper(defaultProps, {
        'avatar-badge': badge,
      });
    });

    it('should render provided `avatar-badge` slot content', () => {
      expect(wrapper.html()).toContain(badge);
    });
  });
});
