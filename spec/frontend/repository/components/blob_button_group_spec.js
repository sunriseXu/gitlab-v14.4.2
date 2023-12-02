import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const DEFAULT_PROPS = {
  name: 'some name',
  path: 'some/path',
  canPushCode: true,
  canPushToBranch: true,
  replacePath: 'some/replace/path',
  deletePath: 'some/delete/path',
  emptyRepo: false,
  projectPath: 'some/project/path',
  isLocked: false,
  canLock: true,
  showForkSuggestion: false,
};

const DEFAULT_INJECT = {
  targetBranch: 'master',
  originalBranch: 'master',
};

describe('BlobButtonGroup component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(BlobButtonGroup, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        ...DEFAULT_INJECT,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDeleteBlobModal = () => wrapper.findComponent(DeleteBlobModal);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findDeleteButton = () => wrapper.findByTestId('delete');
  const findReplaceButton = () => wrapper.findByTestId('replace');

  it('renders component', () => {
    createComponent();

    const { name, path } = DEFAULT_PROPS;

    expect(wrapper.props()).toMatchObject({
      name,
      path,
    });
  });

  describe('buttons', () => {
    beforeEach(() => {
      createComponent();
      jest.spyOn(findUploadBlobModal().vm, 'show');
      jest.spyOn(findDeleteBlobModal().vm, 'show');
    });

    it('renders both the replace and delete button', () => {
      expect(wrapper.findAllComponents(GlButton)).toHaveLength(2);
    });

    it('renders the buttons in the correct order', () => {
      expect(wrapper.findAllComponents(GlButton).at(0).text()).toBe('Replace');
      expect(wrapper.findAllComponents(GlButton).at(1).text()).toBe('Delete');
    });

    it('triggers the UploadBlobModal from the replace button', () => {
      findReplaceButton().trigger('click');

      expect(findUploadBlobModal().vm.show).toHaveBeenCalled();
    });

    it('triggers the DeleteBlobModal from the delete button', () => {
      findDeleteButton().trigger('click');

      expect(findDeleteBlobModal().vm.show).toHaveBeenCalled();
    });

    describe('showForkSuggestion set to true', () => {
      beforeEach(() => {
        createComponent({ showForkSuggestion: true });
        jest.spyOn(findUploadBlobModal().vm, 'show');
        jest.spyOn(findDeleteBlobModal().vm, 'show');
      });

      it('does not trigger the UploadBlobModal from the replace button', () => {
        findReplaceButton().trigger('click');

        expect(findUploadBlobModal().vm.show).not.toHaveBeenCalled();
        expect(wrapper.emitted().fork).toHaveLength(1);
      });

      it('does not trigger the DeleteBlobModal from the delete button', () => {
        findDeleteButton().trigger('click');

        expect(findDeleteBlobModal().vm.show).not.toHaveBeenCalled();
        expect(wrapper.emitted().fork).toHaveLength(1);
      });
    });
  });

  it('renders UploadBlobModal', () => {
    createComponent();

    const { targetBranch, originalBranch } = DEFAULT_INJECT;
    const { name, path, canPushCode, replacePath } = DEFAULT_PROPS;
    const title = `Replace ${name}`;

    expect(findUploadBlobModal().props()).toMatchObject({
      modalTitle: title,
      commitMessage: title,
      targetBranch,
      originalBranch,
      canPushCode,
      path,
      replacePath,
      primaryBtnText: 'Replace file',
    });
  });

  it('renders DeleteBlobModel', () => {
    createComponent();

    const { targetBranch, originalBranch } = DEFAULT_INJECT;
    const { name, canPushCode, deletePath, emptyRepo } = DEFAULT_PROPS;
    const title = `Delete ${name}`;

    expect(findDeleteBlobModal().props()).toMatchObject({
      modalTitle: title,
      commitMessage: title,
      targetBranch,
      originalBranch,
      canPushCode,
      deletePath,
      emptyRepo,
    });
  });
});
