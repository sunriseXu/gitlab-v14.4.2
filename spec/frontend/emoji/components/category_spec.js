import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Category from '~/emoji/components/category.vue';
import EmojiGroup from '~/emoji/components/emoji_group.vue';

let wrapper;
function factory(propsData = {}) {
  wrapper = shallowMount(Category, { propsData });
}

describe('Emoji category component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });
  });

  it('renders emoji groups', () => {
    expect(wrapper.findAllComponents(EmojiGroup).length).toBe(2);
  });

  it('renders group', async () => {
    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    await wrapper.setData({ renderGroup: true });

    expect(wrapper.findComponent(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('renders group on appear', async () => {
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.findComponent(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('emits appear event on appear', async () => {
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.emitted().appear[0]).toEqual(['Activity']);
  });
});
