import { shallowMount } from '@vue/test-utils';
import SecurityDashboard from 'ee/security_dashboard/components/shared/security_dashboard.vue';
import SurveyRequestBanner from 'ee/security_dashboard/components/shared/survey_request_banner.vue';
import gradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import historyQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_history.query.graphql';
import VulnerabilitiesOverTimeChart from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart.vue';
import VulnerabilitySeverities from 'ee/security_dashboard/components/shared/project_security_status_chart.vue';

describe('Security Dashboard Layout component', () => {
  let wrapper;

  const findVulnerabilitiesOverTimeChart = () =>
    wrapper.findComponent(VulnerabilitiesOverTimeChart);
  const findVulnerabilitySeverities = () => wrapper.findComponent(VulnerabilitySeverities);
  const findTitle = () => wrapper.find('h2');
  const findSurveyBanner = () => wrapper.findComponent(SurveyRequestBanner);

  const createWrapper = () => {
    wrapper = shallowMount(SecurityDashboard, {
      propsData: { historyQuery, gradesQuery },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the expected components', () => {
    createWrapper();

    expect(findTitle().text()).toBe(SecurityDashboard.i18n.title);
    expect(findSurveyBanner().exists()).toBe(true);
    expect(findVulnerabilitiesOverTimeChart().props('query')).toBe(historyQuery);
    expect(findVulnerabilitySeverities().props('query')).toBe(gradesQuery);
  });
});
