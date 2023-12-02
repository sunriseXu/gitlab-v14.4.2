import { mount } from '@vue/test-utils';
import { pipelines } from 'test_fixtures/pipelines/pipelines.json';
import PipelineMiniGraph from '~/pipelines/components/pipeline_mini_graph/pipeline_mini_graph.vue';
import PipelineStages from '~/pipelines/components/pipeline_mini_graph/pipeline_stages.vue';
import mockLinkedPipelines from './linked_pipelines_mock_data';

const mockStages = pipelines[0].details.stages;

describe('Pipeline Mini Graph', () => {
  let wrapper;

  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findPipelineStages = () => wrapper.findComponent(PipelineStages);

  const findLinkedPipelineUpstream = () =>
    wrapper.findComponent('[data-testid="pipeline-mini-graph-upstream"]');
  const findLinkedPipelineDownstream = () =>
    wrapper.findComponent('[data-testid="pipeline-mini-graph-downstream"]');
  const findDownstreamArrowIcon = () => wrapper.find('[data-testid="downstream-arrow-icon"]');
  const findUpstreamArrowIcon = () => wrapper.find('[data-testid="upstream-arrow-icon"]');

  const createComponent = (props = {}) => {
    wrapper = mount(PipelineMiniGraph, {
      propsData: {
        stages: mockStages,
        ...props,
      },
    });
  };

  describe('rendered state without upstream or downstream pipelines', () => {
    beforeEach(() => {
      createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render the pipeline stages', () => {
      expect(findPipelineStages().exists()).toBe(true);
    });

    it('should have the correct props', () => {
      expect(findPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: [],
        isMergeTrain: false,
        pipelinePath: '',
        stages: expect.any(Array),
        stagesClass: '',
        updateDropdown: false,
        upstreamPipeline: undefined,
      });
    });

    it('should have no linked pipelines', () => {
      expect(findLinkedPipelineDownstream().exists()).toBe(false);
      expect(findLinkedPipelineUpstream().exists()).toBe(false);
    });

    it('should not render arrow icons', () => {
      expect(findUpstreamArrowIcon().exists()).toBe(false);
      expect(findDownstreamArrowIcon().exists()).toBe(false);
    });

    it('triggers events in "action request complete"', () => {
      createComponent();

      findPipelineMiniGraph(0).vm.$emit('pipelineActionRequestComplete');
      findPipelineMiniGraph(1).vm.$emit('pipelineActionRequestComplete');

      expect(wrapper.emitted('pipelineActionRequestComplete')).toHaveLength(2);
    });
  });

  describe('rendered state with upstream pipeline', () => {
    beforeEach(() => {
      createComponent({
        upstreamPipeline: mockLinkedPipelines.triggered_by,
      });
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should have the correct props', () => {
      expect(findPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: [],
        isMergeTrain: false,
        pipelinePath: '',
        stages: expect.any(Array),
        stagesClass: '',
        updateDropdown: false,
        upstreamPipeline: expect.any(Object),
      });
    });

    it('should render the upstream linked pipelines mini list only', () => {
      expect(findLinkedPipelineUpstream().exists()).toBe(true);
      expect(findLinkedPipelineDownstream().exists()).toBe(false);
    });

    it('should render an upstream arrow icon only', () => {
      expect(findDownstreamArrowIcon().exists()).toBe(false);
      expect(findUpstreamArrowIcon().exists()).toBe(true);
      expect(findUpstreamArrowIcon().props('name')).toBe('long-arrow');
    });
  });

  describe('rendered state with downstream pipelines', () => {
    beforeEach(() => {
      createComponent({
        downstreamPipelines: mockLinkedPipelines.triggered,
        pipelinePath: 'my/pipeline/path',
      });
    });

    it('should have the correct props', () => {
      expect(findPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: expect.any(Array),
        isMergeTrain: false,
        pipelinePath: 'my/pipeline/path',
        stages: expect.any(Array),
        stagesClass: '',
        updateDropdown: false,
        upstreamPipeline: undefined,
      });
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render the downstream linked pipelines mini list only', () => {
      expect(findLinkedPipelineDownstream().exists()).toBe(true);
      expect(findLinkedPipelineUpstream().exists()).toBe(false);
    });

    it('should render a downstream arrow icon only', () => {
      expect(findUpstreamArrowIcon().exists()).toBe(false);
      expect(findDownstreamArrowIcon().exists()).toBe(true);
      expect(findDownstreamArrowIcon().props('name')).toBe('long-arrow');
    });
  });
});
