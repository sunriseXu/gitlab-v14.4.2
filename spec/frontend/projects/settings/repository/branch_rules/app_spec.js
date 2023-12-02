import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BranchRules, { i18n } from '~/projects/settings/repository/branch_rules/app.vue';
import BranchRule from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import branchRulesQuery from '~/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import createFlash from '~/flash';
import { branchRulesMockResponse, propsDataMock } from './mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Branch rules app', () => {
  let wrapper;
  let fakeApollo;

  const branchRulesQuerySuccessHandler = jest.fn().mockResolvedValue(branchRulesMockResponse);

  const createComponent = async ({ queryHandler = branchRulesQuerySuccessHandler } = {}) => {
    fakeApollo = createMockApollo([[branchRulesQuery, queryHandler]]);

    wrapper = mountExtended(BranchRules, {
      apolloProvider: fakeApollo,
      propsData: {
        ...propsDataMock,
      },
    });

    await waitForPromises();
  };

  const findAllBranchRules = () => wrapper.findAllComponents(BranchRule);
  const findEmptyState = () => wrapper.findByTestId('empty');

  beforeEach(() => createComponent());

  it('displays an error if branch rules query fails', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(createFlash).toHaveBeenCalledWith({ message: i18n.queryError });
  });

  it('displays an empty state if no branch rules are present', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(findEmptyState().text()).toBe(i18n.emptyState);
  });

  it('renders branch rules', () => {
    const { nodes } = branchRulesMockResponse.data.project.branchRules;
    expect(findAllBranchRules().at(0).text()).toBe(nodes[0].name);
    expect(findAllBranchRules().at(1).text()).toBe(nodes[1].name);
  });
});
