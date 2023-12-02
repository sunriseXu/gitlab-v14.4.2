import { GlModal, GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import RemoveClusterConfirmation from '~/clusters/components/remove_cluster_confirmation.vue';

describe('Remove cluster confirmation modal', () => {
  let wrapper;

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = mount(RemoveClusterConfirmation, {
      propsData: {
        clusterPath: 'clusterPath',
        clusterName: 'clusterName',
        ...props,
      },
      stubs,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders buttons with modal included', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('two buttons', () => {
    const findModal = () => wrapper.findComponent(GlModal);
    const findRemoveIntegrationButton = () =>
      wrapper.find('[data-testid="remove-integration-button"]');
    const findRemoveIntegrationAndResourcesButton = () =>
      wrapper.find('[data-testid="remove-integration-and-resources-button"]');

    beforeEach(() => {
      createComponent({
        props: { clusterName: 'my-test-cluster' },
        stubs: { GlSprintf, GlModal: stubComponent(GlModal) },
      });
      jest.spyOn(findModal().vm, 'show').mockReturnValue();
    });

    it('open modal with "cleanup" option', async () => {
      findRemoveIntegrationAndResourcesButton().trigger('click');

      await nextTick();

      expect(findModal().vm.show).toHaveBeenCalled();
      expect(wrapper.vm.confirmCleanup).toEqual(true);
      expect(findModal().html()).toContain(
        '<strong>To remove your integration and resources, type <code>my-test-cluster</code> to confirm:</strong>',
      );
    });

    it('open modal without "cleanup" option', async () => {
      findRemoveIntegrationButton().trigger('click');

      await nextTick();

      expect(findModal().vm.show).toHaveBeenCalled();
      expect(wrapper.vm.confirmCleanup).toEqual(false);
      expect(findModal().html()).toContain(
        '<strong>To remove your integration, type <code>my-test-cluster</code> to confirm:</strong>',
      );
    });

    describe('with cluster management project', () => {
      beforeEach(() => {
        createComponent({ props: { hasManagementProject: true } });
      });

      it('renders regular button instead', () => {
        expect(findRemoveIntegrationAndResourcesButton().exists()).toBe(false);
        expect(findRemoveIntegrationButton().exists()).toBe(true);
      });
    });
  });
});
