import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import DescriptionComponent from '~/issues/show/components/description.vue';
import HighlightBar from '~/issues/show/components/incidents/highlight_bar.vue';
import IncidentTabs from '~/issues/show/components/incidents/incident_tabs.vue';
import TimelineTab from '~/issues/show/components/incidents/timeline_events_tab.vue';
import INVALID_URL from '~/lib/utils/invalid_url';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import { descriptionProps } from '../../mock_data/mock_data';

const mockAlert = {
  __typename: 'AlertManagementAlert',
  detailsUrl: INVALID_URL,
  iid: '1',
};

describe('Incident Tabs component', () => {
  let wrapper;

  const mountComponent = (data = {}, options = {}) => {
    wrapper = shallowMount(
      IncidentTabs,
      merge(
        {
          propsData: {
            ...descriptionProps,
          },
          stubs: {
            DescriptionComponent: true,
            MetricsTab: true,
          },
          provide: {
            fullPath: '',
            iid: '',
            projectId: '',
            issuableId: '',
            uploadMetricsFeatureAvailable: true,
            glFeatures: { incidentTimeline: true },
          },
          data() {
            return { alert: mockAlert, ...data };
          },
          mocks: {
            $apollo: {
              queries: {
                alert: {
                  loading: true,
                },
                timelineEvents: {
                  loading: false,
                },
              },
            },
          },
        },
        options,
      ),
    );
  };

  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findSummaryTab = () => findTabs().at(0);
  const findAlertDetailsTab = () => wrapper.find('[data-testid="alert-details-tab"]');
  const findAlertDetailsComponent = () => wrapper.findComponent(AlertDetailsTable);
  const findDescriptionComponent = () => wrapper.findComponent(DescriptionComponent);
  const findHighlightBarComponent = () => wrapper.findComponent(HighlightBar);
  const findTimelineTab = () => wrapper.findComponent(TimelineTab);

  describe('empty state', () => {
    beforeEach(() => {
      mountComponent({ alert: null });
    });

    it('does not show the alert details tab', () => {
      expect(findAlertDetailsComponent().exists()).toBe(false);
    });
  });

  describe('with an alert present', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the summary tab', () => {
      expect(findSummaryTab().exists()).toBe(true);
      expect(findSummaryTab().attributes('title')).toBe('Summary');
    });

    it('renders the alert details tab', () => {
      expect(findAlertDetailsTab().exists()).toBe(true);
      expect(findAlertDetailsTab().attributes('title')).toBe('Alert details');
    });

    it('renders the alert details table with the correct props', () => {
      const alert = { iid: mockAlert.iid };

      expect(findAlertDetailsComponent().props('alert')).toMatchObject(alert);
      expect(findAlertDetailsComponent().props('loading')).toBe(true);
    });

    it('renders the description component with highlight bar', () => {
      expect(findDescriptionComponent().exists()).toBe(true);
      expect(findHighlightBarComponent().exists()).toBe(true);
    });

    it('renders the highlight bar component with the correct props', () => {
      const alert = { detailsUrl: mockAlert.detailsUrl };

      expect(findHighlightBarComponent().props('alert')).toMatchObject(alert);
    });

    it('passes all props to the description component', () => {
      expect(findDescriptionComponent().props()).toMatchObject(descriptionProps);
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mountComponent();
    });

    it('should track incident details views', () => {
      const { category, action } = trackIncidentDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });

  describe('incident timeline tab', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the timeline tab when feature flag is enabled', () => {
      expect(findTimelineTab().exists()).toBe(true);
    });

    it('does not render timeline tab when feature flag is disabled', () => {
      mountComponent({}, { provide: { glFeatures: { incidentTimeline: false } } });

      expect(findTimelineTab().exists()).toBe(false);
    });
  });
});
