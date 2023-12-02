import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { WIDGET } from 'ee/contextual_sidebar/components/constants';
import TrialStatusWidget from 'ee/contextual_sidebar/components/trial_status_widget.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

describe('TrialStatusWidget component', () => {
  let wrapper;

  const { trackingEvents } = WIDGET;
  const trialDaysUsed = 10;
  const trialDuration = 30;
  const daysRemaining = 20;

  const findGlLink = () => wrapper.findComponent(GlLink);

  const createComponent = (providers = {}) => {
    return shallowMount(TrialStatusWidget, {
      provide: {
        trialDaysUsed,
        trialDuration,
        daysRemaining,
        navIconImagePath: 'illustrations/golden_tanuki.svg',
        percentageComplete: 10,
        planName: 'Ultimate',
        plansHref: 'billing/path-for/group',
        ...providers,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent();

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  describe('without the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders without an id', () => {
      expect(findGlLink().attributes('id')).toBe(undefined);
    });

    it('tracks when the widget menu is clicked', () => {
      const { action, ...options } = trackingEvents.widgetClick;
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

      wrapper.find('[data-testid="widget-menu"]').trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, action, { ...options });

      unmockTracking();
    });

    it('does not render Trial twice if the plan name includes "Trial"', () => {
      wrapper = createComponent({ planName: 'Ultimate Trial' });

      expect(wrapper.text()).toMatchInterpolatedText('Ultimate Trial Day 10/30');
    });
  });

  describe('with the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent({ containerId: 'some-id' });
    });

    it('renders with the given id', () => {
      expect(findGlLink().attributes('id')).toBe('some-id');
    });
  });
});
