import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerStatePausedBadge from '~/runner/components/runner_paused_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { I18N_PAUSED } from '~/runner/constants';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerStatePausedBadge, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders paused state', () => {
    expect(wrapper.text()).toBe(I18N_PAUSED);
    expect(findBadge().props('variant')).toBe('warning');
  });

  it('renders tooltip', () => {
    expect(getTooltip().value).toBeDefined();
  });

  it('passes arbitrary attributes to the badge', () => {
    createComponent({ props: { size: 'sm' } });

    expect(findBadge().props('size')).toBe('sm');
  });
});
