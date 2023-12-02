import { GlListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BackgroundMigrationsDatabaseListbox from '~/admin/background_migrations/components/database_listbox.vue';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { MOCK_DATABASES, MOCK_SELECTED_DATABASE } from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

describe('BackgroundMigrationsDatabaseListbox', () => {
  let wrapper;

  const defaultProps = {
    databases: MOCK_DATABASES,
    selectedDatabase: MOCK_SELECTED_DATABASE,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BackgroundMigrationsDatabaseListbox, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlListbox = () => wrapper.findComponent(GlListbox);

  describe('template always', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlListbox', () => {
      expect(findGlListbox().exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('selecting a listbox item fires visitUrl with the database param', () => {
      findGlListbox().vm.$emit('select', MOCK_DATABASES[1].value);

      expect(setUrlParams).toHaveBeenCalledWith({ database: MOCK_DATABASES[1].value });
      expect(visitUrl).toHaveBeenCalled();
    });
  });
});
