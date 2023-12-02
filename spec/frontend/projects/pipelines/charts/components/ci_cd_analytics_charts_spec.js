import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiCdAnalyticsAreaChart from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_area_chart.vue';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import SegmentedControlButtonGroup from '~/vue_shared/components/segmented_control_button_group.vue';
import { transformedAreaChartData, chartOptions } from '../mock_data';

const DEFAULT_PROPS = {
  chartOptions,
  charts: [
    {
      range: 'test range 1',
      title: 'title 1',
      data: transformedAreaChartData,
    },
    {
      range: 'test range 2',
      title: 'title 2',
      data: transformedAreaChartData,
    },
    {
      range: 'test range 3',
      title: 'title 3',
      data: transformedAreaChartData,
    },
  ],
};

describe('~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue', () => {
  let wrapper;

  const createWrapper = (props = {}, slots = {}) =>
    shallowMountExtended(CiCdAnalyticsCharts, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      scopedSlots: {
        ...slots,
      },
    });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findMetricsSlot = () => wrapper.findByTestId('metrics-slot');
  const findSegmentedControl = () => wrapper.findComponent(SegmentedControlButtonGroup);

  describe('segmented control', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should default to the first chart', () => {
      expect(findSegmentedControl().props('value')).toBe(0);
    });

    it('should use the title and index as values', () => {
      const options = findSegmentedControl().props('options');
      expect(options).toHaveLength(3);
      expect(options).toEqual([
        {
          text: 'title 1',
          value: 0,
        },
        {
          text: 'title 2',
          value: 1,
        },
        {
          text: 'title 3',
          value: 2,
        },
      ]);
    });

    it('should select a different chart on change', async () => {
      findSegmentedControl().vm.$emit('input', 1);

      const chart = wrapper.findComponent(CiCdAnalyticsAreaChart);

      await nextTick();

      expect(chart.props('chartData')).toEqual(transformedAreaChartData);
      expect(chart.text()).toBe('Date range: test range 2');
    });
  });

  it('should not display charts if there are no charts', () => {
    wrapper = createWrapper({ charts: [] });
    expect(wrapper.findComponent(CiCdAnalyticsAreaChart).exists()).toBe(false);
  });

  describe('slots', () => {
    beforeEach(() => {
      wrapper = createWrapper(
        {},
        {
          metrics: '<div data-testid="metrics-slot">selected chart: {{props.selectedChart}}</div>',
        },
      );
    });

    it('renders a metrics slot', async () => {
      const selectedChart = 1;
      findSegmentedControl().vm.$emit('input', selectedChart);

      await nextTick();

      expect(findMetricsSlot().text()).toBe(`selected chart: ${selectedChart}`);
    });
  });
});
