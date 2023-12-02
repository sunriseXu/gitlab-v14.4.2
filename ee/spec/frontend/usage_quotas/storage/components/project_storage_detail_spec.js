import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectStorageDetail from 'ee/usage_quotas/storage/components/project_storage_detail.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { projectData, projectHelpLinks } from '../mock_data';

describe('ProjectStorageDetail', () => {
  let wrapper;

  const { storageTypes } = projectData.storage;
  const defaultProps = { storageTypes };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(ProjectStorageDetail, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  beforeEach(() => {
    createComponent();
  });
  afterEach(() => {
    wrapper.destroy();
  });

  describe('with storage types', () => {
    it.each(storageTypes)(
      'renders table row correctly %o',
      ({ storageType: { id, name, description } }) => {
        expect(wrapper.findByTestId(`${id}-name`).text()).toBe(name);
        expect(wrapper.findByTestId(`${id}-description`).text()).toBe(description);
        expect(wrapper.findByTestId(`${id}-icon`).props('name')).toBe(id);
        expect(wrapper.findByTestId(`${id}-help-link`).attributes('href')).toBe(
          projectHelpLinks[id.replace(`Size`, ``)],
        );
      },
    );

    it('should render items in order from the biggest usage size to the smallest', () => {
      const rows = findTable().find('tbody').findAll('tr');
      // Cloning array not to mutate the source
      const sortedStorageTypes = [...storageTypes].sort((a, b) => b.value - a.value);

      sortedStorageTypes.forEach((storageType, i) => {
        const rowUsageAmount = rows.wrappers[i].find('td:last-child').text();
        const expectedUsageAmount = numberToHumanSize(storageType.value, 1);
        expect(rowUsageAmount).toBe(expectedUsageAmount);
      });
    });
  });

  describe('without storage types', () => {
    beforeEach(() => {
      createComponent({ storageTypes: [] });
    });

    it('should render the table header <th>', () => {
      expect(findTable().find('th').exists()).toBe(true);
    });

    it('should not render any table data <td>', () => {
      expect(findTable().find('td').exists()).toBe(false);
    });
  });
});
