import $ from 'jquery';
import Autosave from '~/autosave';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import IssuableForm from '~/issuable/issuable_form';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/autosave');

const createIssuable = (form) => {
  return new IssuableForm(form);
};

describe('IssuableForm', () => {
  let $form;
  let instance;

  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <input name="[title]" />
        <textarea name="[description]"></textarea>
      </form>
    `);
    $form = $('form');
  });

  afterEach(() => {
    resetHTMLFixture();
    $form = null;
    instance = null;
  });

  describe('autosave', () => {
    let $title;
    let $description;

    beforeEach(() => {
      $title = $form.find('input[name*="[title]"]');
      $description = $form.find('textarea[name*="[description]"]');
    });

    afterEach(() => {
      $title = null;
      $description = null;
    });

    describe('initAutosave', () => {
      it('calls initAutosave', () => {
        const initAutosave = jest.spyOn(IssuableForm.prototype, 'initAutosave');
        createIssuable($form);

        expect(initAutosave).toHaveBeenCalledTimes(1);
      });

      it('creates autosave with the searchTerm included', () => {
        setWindowLocation('https://gitlab.test/foo?bar=true');
        createIssuable($form);

        expect(Autosave).toHaveBeenCalledWith(
          $title,
          ['/foo', 'bar=true', 'title'],
          'autosave//foo/bar=true=title',
        );
        expect(Autosave).toHaveBeenCalledWith(
          $description,
          ['/foo', 'bar=true', 'description'],
          'autosave//foo/bar=true=description',
        );
      });

      it("creates autosave fields without the searchTerm if it's an issue new form", () => {
        setWindowLocation('https://gitlab.test/issues/new?bar=true');
        $form.attr('data-new-issue-path', '/issues/new');
        createIssuable($form);

        expect(Autosave).toHaveBeenCalledWith(
          $title,
          ['/issues/new', '', 'title'],
          'autosave//issues/new/bar=true=title',
        );
        expect(Autosave).toHaveBeenCalledWith(
          $description,
          ['/issues/new', '', 'description'],
          'autosave//issues/new/bar=true=description',
        );
      });

      it.each([
        {
          id: 'confidential',
          input: '<input type="checkbox" name="issue[confidential]"/>',
          selector: 'input[name*="[confidential]"]',
        },
        {
          id: 'due_date',
          input: '<input type="text" name="issue[due_date]"/>',
          selector: 'input[name*="[due_date]"]',
        },
      ])('creates $id autosave when $id input exist', ({ id, input, selector }) => {
        $form.append(input);
        const $input = $form.find(selector);
        const totalAutosaveFormFields = $form.children().length;
        createIssuable($form);

        expect(Autosave).toHaveBeenCalledTimes(totalAutosaveFormFields);
        expect(Autosave).toHaveBeenLastCalledWith($input, ['/', '', id], `autosave///=${id}`);
      });
    });

    describe('resetAutosave', () => {
      it('calls reset on title and description', () => {
        instance = createIssuable($form);

        instance.resetAutosave();

        expect(instance.autosaves.get('title').reset).toHaveBeenCalledTimes(1);
        expect(instance.autosaves.get('description').reset).toHaveBeenCalledTimes(1);
      });

      it('resets autosave when submit', () => {
        const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
        createIssuable($form);

        $form.submit();

        expect(resetAutosave).toHaveBeenCalledTimes(1);
      });

      it('resets autosave on elements with the .js-reset-autosave class', () => {
        const resetAutosave = jest.spyOn(IssuableForm.prototype, 'resetAutosave');
        $form.append('<a class="js-reset-autosave">Cancel</a>');
        createIssuable($form);

        $form.find('.js-reset-autosave').trigger('click');

        expect(resetAutosave).toHaveBeenCalledTimes(1);
      });

      it.each([
        { id: 'confidential', input: '<input type="checkbox" name="issue[confidential]"/>' },
        { id: 'due_date', input: '<input type="text" name="issue[due_date]"/>' },
      ])('calls reset on autosave $id when $id input exist', ({ id, input }) => {
        $form.append(input);
        instance = createIssuable($form);
        instance.resetAutosave();

        expect(instance.autosaves.get(id).reset).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('wip', () => {
    beforeEach(() => {
      instance = createIssuable($form);
    });

    describe('removeWip', () => {
      it.each`
        prefix
        ${'draFT: '}
        ${'  [DRaft] '}
        ${'drAft:'}
        ${'[draFT]'}
        ${'(draft) '}
        ${' (DrafT)'}
        ${'draft: [draft] (draft)'}
      `('removes "$prefix" from the beginning of the title', ({ prefix }) => {
        instance.titleField.val(`${prefix}The Issuable's Title Value`);

        instance.removeWip();

        expect(instance.titleField.val()).toBe("The Issuable's Title Value");
      });
    });

    describe('addWip', () => {
      it("properly adds the work in progress prefix to the Issuable's title", () => {
        instance.titleField.val("The Issuable's Title Value");

        instance.addWip();

        expect(instance.titleField.val()).toBe("Draft: The Issuable's Title Value");
      });
    });

    describe('workInProgress', () => {
      it.each`
        title                                 | expected
        ${'draFT: something is happening'}    | ${true}
        ${'draft something is happening'}     | ${false}
        ${'something is happening to drafts'} | ${false}
        ${'something is happening'}           | ${false}
      `('returns $expected with "$title"', ({ title, expected }) => {
        instance.titleField.val(title);

        expect(instance.workInProgress()).toBe(expected);
      });
    });
  });
});
