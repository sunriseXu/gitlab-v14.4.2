import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { formatDate } from '~/lib/utils/datetime_utility';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

describe('RichTimestampTooltip', () => {
  const currentDate = new Date();
  const mockRawTimestamp = currentDate.toISOString();
  const mockTimestamp = formatDate(currentDate);
  let wrapper;

  const createComponent = ({
    target = 'some-element',
    rawTimestamp = mockRawTimestamp,
    timestampTypeText = 'Created',
  } = {}) => {
    wrapper = shallowMountExtended(RichTimestampTooltip, {
      propsData: {
        target,
        rawTimestamp,
        timestampTypeText,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the tooltip text header', () => {
    expect(wrapper.findByTestId('header-text').text()).toBe('Created just now');
  });

  it('renders the tooltip text body', () => {
    expect(wrapper.findByTestId('body-text').text()).toBe(mockTimestamp);
  });
});
