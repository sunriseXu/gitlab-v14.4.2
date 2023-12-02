import { GlAlert, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import CodeCoverage from '~/pages/projects/graphs/components/code_coverage.vue';
import { codeCoverageMockData, sortedDataByDates } from './mock_data';

describe('Code Coverage', () => {
  let wrapper;
  let mockAxios;

  const graphEndpoint = '/graph';
  const graphStartDate = '13 February';
  const graphEndDate = '12 May';
  const graphRef = 'master';
  const graphCsvPath = 'url/';

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstDropdownItem = () => findAllDropdownItems().at(0);
  const findSecondDropdownItem = () => findAllDropdownItems().at(1);
  const findDownloadButton = () => wrapper.find('[data-testid="download-button"]');

  const createComponent = () => {
    wrapper = shallowMount(CodeCoverage, {
      propsData: {
        graphEndpoint,
        graphStartDate,
        graphEndDate,
        graphRef,
        graphCsvPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when fetching data is successful', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(httpStatusCodes.OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders the area chart', () => {
      expect(findAreaChart().exists()).toBe(true);
    });

    it('sorts the dates in ascending order', () => {
      expect(wrapper.vm.sortedData).toEqual(sortedDataByDates);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('shows no error messages', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not render download button', () => {
      expect(findDownloadButton().exists()).toBe(true);
    });
  });

  describe('when fetching data fails', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(httpStatusCodes.BAD_REQUEST);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders an error message', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes().variant).toBe('danger');
    });

    it('still renders an empty graph', () => {
      expect(findAreaChart().exists()).toBe(true);
    });
  });

  describe('when fetching data succeed but returns an empty state', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(httpStatusCodes.OK, []);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders an information message', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes().variant).toBe('info');
    });

    it('still renders an empty graph', () => {
      expect(findAreaChart().exists()).toBe(true);
    });

    it('does not render download button', () => {
      expect(findDownloadButton().exists()).toBe(false);
    });
  });

  describe('dropdown options', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(httpStatusCodes.OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    it('renders the dropdown with all custom names as options', () => {
      expect(wrapper.findComponent(GlDropdown).exists()).toBeDefined();
      expect(findAllDropdownItems()).toHaveLength(codeCoverageMockData.length);
      expect(findFirstDropdownItem().text()).toBe(codeCoverageMockData[0].group_name);
    });
  });

  describe('interactions', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(httpStatusCodes.OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    it('updates the selected dropdown option with an icon', async () => {
      findSecondDropdownItem().vm.$emit('click');

      await nextTick();

      expect(findFirstDropdownItem().attributes('ischecked')).toBe(undefined);
      expect(findSecondDropdownItem().attributes('ischecked')).toBe('true');
    });

    it('updates the graph data when selecting a different option in dropdown', async () => {
      const originalSelectedData = wrapper.vm.selectedDailyCoverage;
      const expectedData = codeCoverageMockData[1];

      findSecondDropdownItem().vm.$emit('click');

      await nextTick();

      expect(wrapper.vm.selectedDailyCoverage).not.toBe(originalSelectedData);
      expect(wrapper.vm.selectedDailyCoverage).toBe(expectedData);
    });
  });
});
