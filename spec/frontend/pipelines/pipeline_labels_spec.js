import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import PipelineLabelsComponent from '~/pipelines/components/pipelines_list/pipeline_labels.vue';
import { mockPipeline } from './mock_data';

const projectPath = 'test/test';

describe('Pipeline label component', () => {
  let wrapper;

  const findScheduledTag = () => wrapper.findByTestId('pipeline-url-scheduled');
  const findLatestTag = () => wrapper.findByTestId('pipeline-url-latest');
  const findYamlTag = () => wrapper.findByTestId('pipeline-url-yaml');
  const findStuckTag = () => wrapper.findByTestId('pipeline-url-stuck');
  const findAutoDevopsTag = () => wrapper.findByTestId('pipeline-url-autodevops');
  const findAutoDevopsTagLink = () => wrapper.findByTestId('pipeline-url-autodevops-link');
  const findDetachedTag = () => wrapper.findByTestId('pipeline-url-detached');
  const findFailureTag = () => wrapper.findByTestId('pipeline-url-failure');
  const findForkTag = () => wrapper.findByTestId('pipeline-url-fork');
  const findTrainTag = () => wrapper.findByTestId('pipeline-url-train');

  const defaultProps = mockPipeline(projectPath);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(PipelineLabelsComponent, {
      propsData: { ...defaultProps, ...props },
      provide: {
        targetProjectFullPath: projectPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should not render tags when flags are not set', () => {
    createComponent();

    expect(findStuckTag().exists()).toBe(false);
    expect(findLatestTag().exists()).toBe(false);
    expect(findYamlTag().exists()).toBe(false);
    expect(findAutoDevopsTag().exists()).toBe(false);
    expect(findFailureTag().exists()).toBe(false);
    expect(findScheduledTag().exists()).toBe(false);
    expect(findForkTag().exists()).toBe(false);
    expect(findTrainTag().exists()).toBe(false);
  });

  it('should render the stuck tag when flag is provided', () => {
    const stuckPipeline = defaultProps.pipeline;
    stuckPipeline.flags.stuck = true;

    createComponent({
      ...stuckPipeline.pipeline,
    });

    expect(findStuckTag().text()).toContain('stuck');
  });

  it('should render latest tag when flag is provided', () => {
    const latestPipeline = defaultProps.pipeline;
    latestPipeline.flags.latest = true;

    createComponent({
      ...latestPipeline,
    });

    expect(findLatestTag().text()).toContain('latest');
  });

  it('should render a yaml badge when it is invalid', () => {
    const yamlPipeline = defaultProps.pipeline;
    yamlPipeline.flags.yaml_errors = true;

    createComponent({
      ...yamlPipeline,
    });

    expect(findYamlTag().text()).toContain('yaml invalid');
  });

  it('should render an autodevops badge when flag is provided', () => {
    const autoDevopsPipeline = defaultProps.pipeline;
    autoDevopsPipeline.flags.auto_devops = true;

    createComponent({
      ...autoDevopsPipeline,
    });

    expect(trimText(findAutoDevopsTag().text())).toBe('Auto DevOps');

    expect(findAutoDevopsTagLink().attributes()).toMatchObject({
      href: '/help/topics/autodevops/index.md',
      target: '_blank',
    });
  });

  it('should render a detached badge when flag is provided', () => {
    const detachedMRPipeline = defaultProps.pipeline;
    detachedMRPipeline.flags.detached_merge_request_pipeline = true;

    createComponent({
      ...detachedMRPipeline,
    });

    expect(findDetachedTag().text()).toBe('merge request');
  });

  it('should render error badge when pipeline has a failure reason set', () => {
    const failedPipeline = defaultProps.pipeline;
    failedPipeline.flags.failure_reason = true;
    failedPipeline.failure_reason = 'some reason';

    createComponent({
      ...failedPipeline,
    });

    expect(findFailureTag().text()).toContain('error');
    expect(findFailureTag().attributes('title')).toContain('some reason');
  });

  it('should render scheduled badge when pipeline was triggered by a schedule', () => {
    const scheduledPipeline = defaultProps.pipeline;
    scheduledPipeline.source = 'schedule';

    createComponent({
      ...scheduledPipeline,
    });

    expect(findScheduledTag().exists()).toBe(true);
    expect(findScheduledTag().text()).toContain('Scheduled');
  });

  it('should render the fork badge when the pipeline was run in a fork', () => {
    const forkedPipeline = defaultProps.pipeline;
    forkedPipeline.project.full_path = '/test/forked';

    createComponent({
      ...forkedPipeline,
    });

    expect(findForkTag().exists()).toBe(true);
    expect(findForkTag().text()).toBe('fork');
  });

  it('should render the train badge when the pipeline is a merge train pipeline', () => {
    const mergeTrainPipeline = defaultProps.pipeline;
    mergeTrainPipeline.flags.merge_train_pipeline = true;

    createComponent({
      ...mergeTrainPipeline,
    });

    expect(findTrainTag().text()).toBe('merge train');
  });

  it('should not render the train badge when the pipeline is not a merge train pipeline', () => {
    const mergeTrainPipeline = defaultProps.pipeline;
    mergeTrainPipeline.flags.merge_train_pipeline = false;

    createComponent({
      ...mergeTrainPipeline,
    });

    expect(findTrainTag().exists()).toBe(false);
  });
});
