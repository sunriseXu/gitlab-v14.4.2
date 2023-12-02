import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import SecurityTrainingPromoBanner from 'ee/security_dashboard/components/project/security_training_promo_banner.vue';
import {
  TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION,
  TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
} from '~/security_configuration/constants';

const SECURITY_CONFIGURATION_PATH = 'foo/bar';
const VULNERABILITY_MANAGEMENT_TAB_NAME = 'vulnerability-management';
const PROJECT_FULL_PATH = 'namespace/project';

describe('Security training promo banner component', () => {
  let wrapper;
  const userCalloutDismissSpy = jest.fn();

  const createWrapper = ({ shouldShowCallout = true } = {}) =>
    shallowMount(SecurityTrainingPromoBanner, {
      provide: {
        projectFullPath: PROJECT_FULL_PATH,
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('banner', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should be an introduction that announces the security training feature', () => {
      const { title, buttonText, content } = SecurityTrainingPromoBanner.i18n;

      expect(findBanner().props()).toMatchObject({
        variant: 'introduction',
        title,
        buttonText,
      });
      expect(findBanner().text()).toBe(content);
    });

    it(`should link to the security configuration's vulnerability management tab`, () => {
      expect(findBanner().props('buttonLink')).toBe(
        `${SECURITY_CONFIGURATION_PATH}?tab=${VULNERABILITY_MANAGEMENT_TAB_NAME}`,
      );
    });
  });

  describe('dismissal', () => {
    it('should dismiss the callout when the banner is closed', () => {
      wrapper = createWrapper();

      expect(userCalloutDismissSpy).not.toHaveBeenCalled();

      findBanner().vm.$emit('close');

      expect(userCalloutDismissSpy).toHaveBeenCalled();
    });

    it('should not show the banner once it has been dismissed', () => {
      wrapper = createWrapper({ shouldShowCallout: false });

      expect(findBanner().exists()).toBe(false);
    });
  });

  describe('metrics', () => {
    let trackingSpy;

    beforeEach(async () => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      wrapper = createWrapper();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks clicks on the CTA button', () => {
      expect(trackingSpy).not.toHaveBeenCalled();

      findBanner().vm.$emit('primary');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION, {
        label: TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
        property: PROJECT_FULL_PATH,
      });
    });
  });
});
