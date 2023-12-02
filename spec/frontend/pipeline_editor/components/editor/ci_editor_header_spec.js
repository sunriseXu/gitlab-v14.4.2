import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiEditorHeader from '~/pipeline_editor/components/editor/ci_editor_header.vue';
import {
  pipelineEditorTrackingOptions,
  TEMPLATE_REPOSITORY_URL,
} from '~/pipeline_editor/constants';

describe('CI Editor Header', () => {
  let wrapper;
  let trackingSpy = null;

  const createComponent = ({ showDrawer = false } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CiEditorHeader, {
        propsData: {
          showDrawer,
        },
      }),
    );
  };

  const findLinkBtn = () => wrapper.findByTestId('template-repo-link');
  const findHelpBtn = () => wrapper.findByTestId('drawer-toggle');

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  const testTracker = async (element, expectedAction) => {
    const { label } = pipelineEditorTrackingOptions;

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    await element.vm.$emit('click');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, expectedAction, {
      label,
    });
  };

  describe('link button', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('finds the browse template button', () => {
      expect(findLinkBtn().exists()).toBe(true);
    });

    it('contains the link to the template repo', () => {
      expect(findLinkBtn().attributes('href')).toBe(TEMPLATE_REPOSITORY_URL);
    });

    it('has the external-link icon', () => {
      expect(findLinkBtn().props('icon')).toBe('external-link');
    });

    it('tracks the click on the browse button', async () => {
      const { browseTemplates } = pipelineEditorTrackingOptions.actions;

      testTracker(findLinkBtn(), browseTemplates);
    });
  });

  describe('help button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds the help button', () => {
      expect(findHelpBtn().exists()).toBe(true);
    });

    it('has the information-o icon', () => {
      expect(findHelpBtn().props('icon')).toBe('information-o');
    });

    describe('when pipeline editor drawer is closed', () => {
      beforeEach(() => {
        createComponent({ showDrawer: false });
      });

      it('emits open drawer event when clicked', () => {
        expect(wrapper.emitted('open-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('open-drawer')).toHaveLength(1);
      });

      it('tracks open help drawer action', async () => {
        const { actions } = pipelineEditorTrackingOptions;

        testTracker(findHelpBtn(), actions.openHelpDrawer);
      });
    });

    describe('when pipeline editor drawer is open', () => {
      beforeEach(() => {
        createComponent({ showDrawer: true });
      });

      it('emits close drawer event when clicked', () => {
        expect(wrapper.emitted('close-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('close-drawer')).toHaveLength(1);
      });
    });
  });
});
