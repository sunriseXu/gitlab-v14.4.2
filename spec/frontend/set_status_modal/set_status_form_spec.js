import $ from 'jquery';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import EmojiPicker from '~/emoji/components/picker.vue';
import { timeRanges } from '~/vue_shared/constants';
import { sprintf } from '~/locale';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';

describe('SetStatusForm', () => {
  let wrapper;

  const defaultPropsData = {
    defaultEmoji: 'speech_balloon',
    emoji: 'thumbsup',
    message: 'Foo bar',
    availability: false,
  };

  const createComponent = async ({ propsData = {} } = {}) => {
    wrapper = mountExtended(SetStatusForm, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });

    await waitForPromises();
  };

  const findMessageInput = () =>
    wrapper.findByPlaceholderText(SetStatusForm.i18n.statusMessagePlaceholder);
  const findSelectedEmoji = (emoji) =>
    wrapper.findByTestId('selected-emoji').find(`gl-emoji[data-name="${emoji}"]`);

  it('sets up emoji autocomplete for the message input', async () => {
    const gfmAutoCompleteSetupSpy = jest.spyOn(GfmAutoComplete.prototype, 'setup');

    await createComponent();

    expect(gfmAutoCompleteSetupSpy).toHaveBeenCalledWith($(findMessageInput().element), {
      emojis: true,
    });
  });

  describe('when emoji is set', () => {
    it('displays emoji', async () => {
      await createComponent();

      expect(findSelectedEmoji(defaultPropsData.emoji).exists()).toBe(true);
    });
  });

  describe('when emoji is not set and message is changed', () => {
    it('displays default emoji', async () => {
      await createComponent({
        propsData: {
          emoji: '',
        },
      });

      await findMessageInput().trigger('keyup');

      expect(findSelectedEmoji(defaultPropsData.defaultEmoji).exists()).toBe(true);
    });
  });

  describe('when message is set', () => {
    it('displays filled in message input', async () => {
      await createComponent();

      expect(findMessageInput().element.value).toBe(defaultPropsData.message);
    });
  });

  describe('when clear status after is set', () => {
    it('displays value in dropdown toggle button', async () => {
      const clearStatusAfter = timeRanges[0];

      await createComponent({
        propsData: {
          clearStatusAfter,
        },
      });

      expect(wrapper.findByRole('button', { name: clearStatusAfter.label }).exists()).toBe(true);
    });
  });

  describe('when emoji is changed', () => {
    beforeEach(async () => {
      await createComponent();

      wrapper.findComponent(EmojiPicker).vm.$emit('click', defaultPropsData.emoji);
    });

    it('emits `emoji-click` event', () => {
      expect(wrapper.emitted('emoji-click')).toEqual([[defaultPropsData.emoji]]);
    });
  });

  describe('when message is changed', () => {
    it('emits `message-input` event', async () => {
      await createComponent();

      const newMessage = 'Foo bar baz';

      await findMessageInput().setValue(newMessage);

      expect(wrapper.emitted('message-input')).toEqual([[newMessage]]);
    });
  });

  describe('when availability checkbox is changed', () => {
    it('emits `availability-input` event', async () => {
      await createComponent();

      await wrapper
        .findByLabelText(
          `${SetStatusForm.i18n.availabilityCheckboxLabel} ${SetStatusForm.i18n.availabilityCheckboxHelpText}`,
        )
        .setChecked();

      expect(wrapper.emitted('availability-input')).toEqual([[true]]);
    });
  });

  describe('when `Clear status after` dropdown is changed', () => {
    it('emits `clear-status-after-click`', async () => {
      await wrapper.findByTestId('thirtyMinutes').trigger('click');

      expect(wrapper.emitted('clear-status-after-click')).toEqual([[timeRanges[0]]]);
    });
  });

  describe('when clear status button is clicked', () => {
    beforeEach(async () => {
      await createComponent();

      await wrapper
        .findByRole('button', { name: SetStatusForm.i18n.clearStatusButtonLabel })
        .trigger('click');
    });

    it('clears emoji and message', () => {
      expect(wrapper.emitted('emoji-click')).toEqual([['']]);
      expect(wrapper.emitted('message-input')).toEqual([['']]);
      expect(wrapper.findByTestId('no-emoji-placeholder').exists()).toBe(true);
    });
  });

  describe('when `currentClearStatusAfter` prop is set', () => {
    it('displays clear status message', async () => {
      const date = '2022-08-25 21:14:48 UTC';

      await createComponent({
        propsData: {
          currentClearStatusAfter: date,
        },
      });

      expect(
        wrapper.findByText(sprintf(SetStatusForm.i18n.clearStatusAfterMessage, { date })).exists(),
      ).toBe(true);
    });
  });
});
