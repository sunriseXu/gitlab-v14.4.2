import $ from 'jquery';
import Autosave from '~/autosave';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import IssuableForm from 'ee/issuable/issuable_form';
import IssuableFormCE from '~/issuable/issuable_form';

jest.mock('~/autosave');

const createIssuable = (form) => {
  return new IssuableForm(form);
};

describe('IssuableForm', () => {
  let $form;

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
  });

  describe('initAutosave', () => {
    it('calls super initAutosave', () => {
      const initAutosaveCE = jest.spyOn(IssuableFormCE.prototype, 'initAutosave');
      createIssuable($form);
      expect(initAutosaveCE).toHaveBeenCalledTimes(1);
    });

    it('creates weight autosave when weight input exist', () => {
      $form.append('<input name="[weight]" />');
      const $weight = $form.find('input[name*="[weight]"]');
      const totalAutosaveFormFields = $form.children().length;
      createIssuable($form);

      expect(Autosave).toHaveBeenCalledTimes(totalAutosaveFormFields);
      expect(Autosave).toHaveBeenLastCalledWith($weight, ['/', '', 'weight'], 'autosave///=weight');
    });
  });

  describe('resetAutosave', () => {
    it('calls super resetAutosave', () => {
      const resetAutosaveCE = jest.spyOn(IssuableFormCE.prototype, 'resetAutosave');
      createIssuable($form).resetAutosave();

      expect(resetAutosaveCE).toHaveBeenCalledTimes(1);
    });

    it('calls reset on weight when weight input exist', () => {
      $form.append('<input name="[weight]" />');
      const instance = createIssuable($form);
      instance.resetAutosave();

      expect(instance.autosaves.get('weight').reset).toHaveBeenCalledTimes(1);
    });
  });
});
