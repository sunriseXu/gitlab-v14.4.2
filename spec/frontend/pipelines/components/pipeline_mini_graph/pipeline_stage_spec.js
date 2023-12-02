import { GlDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import axios from '~/lib/utils/axios_utils';
import PipelineStage from '~/pipelines/components/pipeline_mini_graph/pipeline_stage.vue';
import eventHub from '~/pipelines/event_hub';
import waitForPromises from 'helpers/wait_for_promises';
import { stageReply } from '../../mock_data';

const dropdownPath = 'path.json';

describe('Pipelines stage component', () => {
  let wrapper;
  let mock;
  let glTooltipDirectiveMock;

  const createComponent = (props = {}) => {
    glTooltipDirectiveMock = jest.fn();
    wrapper = mount(PipelineStage, {
      attachTo: document.body,
      directives: {
        GlTooltip: glTooltipDirectiveMock,
      },
      propsData: {
        stage: {
          status: {
            group: 'success',
            icon: 'status_success',
            title: 'success',
          },
          dropdown_path: dropdownPath,
        },
        updateDropdown: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(eventHub, '$emit');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    eventHub.$emit.mockRestore();
    mock.restore();
  });

  const findCiActionBtn = () => wrapper.find('.js-ci-action');
  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggle = () => wrapper.find('button.dropdown-toggle');
  const findDropdownMenu = () =>
    wrapper.find('[data-testid="mini-pipeline-graph-dropdown-menu-list"]');
  const findDropdownMenuTitle = () =>
    wrapper.find('[data-testid="pipeline-stage-dropdown-menu-title"]');
  const findMergeTrainWarning = () => wrapper.find('[data-testid="warning-message-merge-trains"]');
  const findLoadingState = () => wrapper.find('[data-testid="pipeline-stage-loading-state"]');

  const openStageDropdown = async () => {
    await findDropdownToggle().trigger('click');
    await waitForPromises();
    await nextTick();
  };

  describe('loading state', () => {
    beforeEach(async () => {
      createComponent({ updateDropdown: true });

      mock.onGet(dropdownPath).reply(200, stageReply);

      await openStageDropdown();
    });

    it('displays loading state while jobs are being fetched', async () => {
      jest.runOnlyPendingTimers();
      await nextTick();

      expect(findLoadingState().exists()).toBe(true);
      expect(findLoadingState().text()).toBe(PipelineStage.i18n.loadingText);
    });

    it('does not display loading state after jobs have been fetched', async () => {
      await waitForPromises();

      expect(findLoadingState().exists()).toBe(false);
    });
  });

  describe('default appearance', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets up the tooltip to not have a show delay animation', () => {
      expect(glTooltipDirectiveMock.mock.calls[0][1].modifiers.ds0).toBe(true);
    });

    it('renders a dropdown with the status icon', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownToggle().exists()).toBe(true);
      expect(findCiIcon().exists()).toBe(true);
    });

    it('renders a borderless ci-icon', () => {
      expect(findCiIcon().exists()).toBe(true);
      expect(findCiIcon().props('isBorderless')).toBe(true);
      expect(findCiIcon().classes('borderless')).toBe(true);
    });

    it('renders a ci-icon with a custom border class', () => {
      expect(findCiIcon().exists()).toBe(true);
      expect(findCiIcon().classes('gl-border')).toBe(true);
    });
  });

  describe('when user opens dropdown and stage request is successful', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent();

      await openStageDropdown();
      await jest.runAllTimers();
      await axios.waitForAll();
    });

    it('renders the received data and emits the correct events', async () => {
      expect(findDropdownMenu().text()).toContain(stageReply.latest_statuses[0].name);
      expect(findDropdownMenuTitle().text()).toContain(stageReply.name);
      expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
      expect(wrapper.emitted('miniGraphStageClick')).toEqual([[]]);
    });

    it('refreshes when updateDropdown is set to true', async () => {
      expect(mock.history.get).toHaveLength(1);

      wrapper.setProps({ updateDropdown: true });
      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(2);
    });
  });

  describe('when user opens dropdown and stage request fails', () => {
    it('should close the dropdown', async () => {
      mock.onGet(dropdownPath).reply(500);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
      await waitForPromises();

      expect(findDropdown().classes('show')).toBe(false);
    });
  });

  describe('update endpoint correctly', () => {
    beforeEach(async () => {
      const copyStage = { ...stageReply };
      copyStage.latest_statuses[0].name = 'this is the updated content';
      mock.onGet('bar.json').reply(200, copyStage);
      createComponent({
        stage: {
          status: {
            group: 'running',
            icon: 'status_running',
            title: 'running',
          },
          dropdown_path: 'bar.json',
        },
      });
      await axios.waitForAll();
    });

    it('should update the stage to request the new endpoint provided', async () => {
      await openStageDropdown();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(findDropdownMenu().text()).toContain('this is the updated content');
    });
  });

  describe('pipelineActionRequestComplete', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      mock.onPost(`${stageReply.latest_statuses[0].status.action.path}.json`).reply(200);

      createComponent();
      await waitForPromises();
      await nextTick();
    });

    const clickCiAction = async () => {
      await openStageDropdown();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      await findCiActionBtn().trigger('click');
    };

    it('closes dropdown when job item action is clicked', async () => {
      const hidden = jest.fn();

      wrapper.vm.$root.$on('bv::dropdown::hide', hidden);

      expect(hidden).toHaveBeenCalledTimes(0);

      await clickCiAction();
      await waitForPromises();

      expect(hidden).toHaveBeenCalledTimes(1);
    });

    it('emits `pipelineActionRequestComplete` when job item action is clicked', async () => {
      await clickCiAction();
      await waitForPromises();

      expect(wrapper.emitted('pipelineActionRequestComplete')).toHaveLength(1);
    });
  });

  describe('With merge trains enabled', () => {
    it('shows a warning on the dropdown', async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent({
        isMergeTrain: true,
      });

      await openStageDropdown();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      const warning = findMergeTrainWarning();

      expect(warning.text()).toBe('Merge train pipeline jobs can not be retried');
    });
  });

  describe('With merge trains disabled', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
    });

    it('does not show a warning on the dropdown', () => {
      const warning = findMergeTrainWarning();

      expect(warning.exists()).toBe(false);
    });
  });
});
