import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeFormCore from 'ee/geo_node_form/components/geo_node_form_core.vue';
import { VALIDATION_FIELD_KEYS } from 'ee/geo_node_form/constants';
import { MOCK_NODE, STRING_OVER_255 } from '../mock_data';

Vue.use(Vuex);

describe('GeoNodeFormCore', () => {
  let wrapper;
  let store;

  const defaultProps = {
    nodeData: MOCK_NODE,
  };

  const createComponent = (props = {}) => {
    store = new Vuex.Store({
      state: {
        formErrors: Object.values(VALIDATION_FIELD_KEYS).reduce(
          (acc, cur) => ({ ...acc, [cur]: '' }),
          {},
        ),
      },
      actions: {
        setError({ state }, { key, error }) {
          state.formErrors[key] = error;
        },
      },
    });

    wrapper = mount(GeoNodeFormCore, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormNameField = () => wrapper.find('#node-name-field');
  const findGeoNodeFormUrlField = () => wrapper.find('#node-url-field');
  const findGeoNodeInternalUrlField = () => wrapper.find('#node-internal-url-field');
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Node Form Name Field', () => {
      expect(findGeoNodeFormNameField().exists()).toBe(true);
    });

    it('renders Geo Node Form Url Field', () => {
      expect(findGeoNodeFormUrlField().exists()).toBe(true);
    });

    describe.each`
      primaryNode
      ${true}
      ${false}
    `('internal URL', ({ primaryNode }) => {
      describe(`when node is ${primaryNode ? 'primary' : 'secondary'}`, () => {
        beforeEach(() => {
          createComponent({
            nodeData: { ...defaultProps.nodeData, primary: primaryNode },
          });
        });

        it('shows the Internal URL Field', () => {
          expect(findGeoNodeInternalUrlField().exists()).toBe(true);
        });
      });
    });

    describe('errors', () => {
      describe.each`
        data               | showError | errorMessage
        ${null}            | ${true}   | ${"Site name can't be blank"}
        ${''}              | ${true}   | ${"Site name can't be blank"}
        ${STRING_OVER_255} | ${true}   | ${'Site name should be between 1 and 255 characters'}
        ${'Test'}          | ${false}  | ${null}
      `(`Name Field`, ({ data, showError, errorMessage }) => {
        beforeEach(() => {
          createComponent();
          findGeoNodeFormNameField().setValue(data);
        });

        it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
          expect(findGeoNodeFormNameField().classes('is-invalid')).toBe(showError);
          if (showError) {
            expect(findErrorMessage().text()).toBe(errorMessage);
          }
        });
      });
    });

    describe.each`
      data                    | showError | errorMessage
      ${null}                 | ${true}   | ${"URL can't be blank"}
      ${''}                   | ${true}   | ${"URL can't be blank"}
      ${'abcd'}               | ${true}   | ${'URL must be a valid url (ex: https://gitlab.com)'}
      ${'https://gitlab.com'} | ${false}  | ${null}
    `(`URL Field`, ({ data, showError, errorMessage }) => {
      beforeEach(() => {
        createComponent();
        findGeoNodeFormUrlField().setValue(data);
      });

      it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
        expect(findGeoNodeFormUrlField().classes('is-invalid')).toBe(showError);
        if (showError) {
          expect(findErrorMessage().text()).toBe(errorMessage);
        }
      });
    });
  });
});
