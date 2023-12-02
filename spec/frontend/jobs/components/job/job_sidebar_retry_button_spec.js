import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobsSidebarRetryButton from '~/jobs/components/job/sidebar/job_sidebar_retry_button.vue';
import createStore from '~/jobs/store';
import job from '../../mock_data';

describe('Job Sidebar Retry Button', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findRetryButton = () => wrapper.findByTestId('retry-job-button');
  const findRetryLink = () => wrapper.findByTestId('retry-job-link');

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = shallowMountExtended(JobsSidebarRetryButton, {
      propsData: {
        href: job.retry_path,
        modalId: 'modal-id',
        ...props,
      },
      store,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  beforeEach(createWrapper);

  it.each([
    [null, false, true],
    ['unmet_prerequisites', false, true],
    [forwardDeploymentFailure, true, false],
  ])(
    'when error is: %s, should render button: %s | should render link: %s',
    async (failureReason, buttonExists, linkExists) => {
      await store.dispatch('receiveJobSuccess', { ...job, failure_reason: failureReason });

      expect(findRetryButton().exists()).toBe(buttonExists);
      expect(findRetryLink().exists()).toBe(linkExists);
    },
  );

  describe('Button', () => {
    it('should have the correct configuration', async () => {
      await store.dispatch('receiveJobSuccess', { failure_reason: forwardDeploymentFailure });

      expect(findRetryButton().attributes()).toMatchObject({
        category: 'primary',
        variant: 'confirm',
        icon: 'retry',
      });
    });
  });

  describe('Link', () => {
    it('should have the correct configuration', () => {
      expect(findRetryLink().attributes()).toMatchObject({
        'data-method': 'post',
        href: job.retry_path,
        icon: 'retry',
      });
    });
  });
});
