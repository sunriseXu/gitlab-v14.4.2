import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TableEmptyState from 'ee/groups/settings/compliance_frameworks/components/table_empty_state.vue';

describe('TableEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const createComponent = (props = {}) => {
    wrapper = shallowMount(TableEmptyState, {
      propsData: {
        imagePath: 'dir/image.svg',
        addFrameworkPath: 'group/framework/new',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('has the correct props', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      description: 'Frameworks that have been added will appear here.',
      svgPath: 'dir/image.svg',
      primaryButtonLink: 'group/framework/new',
      primaryButtonText: 'Add framework',
      svgHeight: 100,
      compact: true,
    });
  });

  it('displays the correct title', () => {
    createComponent();

    expect(findEmptyState().find('h5').text()).toBe('No compliance frameworks are set up yet');
  });
});
