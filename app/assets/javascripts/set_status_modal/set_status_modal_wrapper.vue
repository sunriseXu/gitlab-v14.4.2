<script>
import { GlToast, GlTooltipDirective, GlSafeHtmlDirective, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import createFlash from '~/flash';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { updateUserStatus } from '~/rest_api';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { isUserBusy } from './utils';
import { NEVER_TIME_RANGE, AVAILABILITY_STATUS } from './constants';
import SetStatusForm from './set_status_form.vue';

Vue.use(GlToast);

export default {
  components: {
    GlModal,
    SetStatusForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    defaultEmoji: {
      type: String,
      required: false,
      default: '',
    },
    currentEmoji: {
      type: String,
      required: true,
    },
    currentMessage: {
      type: String,
      required: true,
    },
    currentAvailability: {
      type: String,
      required: false,
      default: '',
    },
    currentClearStatusAfter: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      defaultEmojiTag: '',
      emoji: this.currentEmoji,
      message: this.currentMessage,
      modalId: 'set-user-status-modal',
      availability: isUserBusy(this.currentAvailability),
      clearStatusAfter: NEVER_TIME_RANGE,
    };
  },
  mounted() {
    this.$root.$emit(BV_SHOW_MODAL, this.modalId);
  },
  methods: {
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    removeStatus() {
      this.availability = false;
      this.emoji = '';
      this.message = '';
      this.setStatus();
    },
    setStatus() {
      const { emoji, message, availability, clearStatusAfter } = this;

      updateUserStatus({
        emoji,
        message,
        availability: availability ? AVAILABILITY_STATUS.BUSY : AVAILABILITY_STATUS.NOT_SET,
        clearStatusAfter:
          clearStatusAfter.label === NEVER_TIME_RANGE.label ? null : clearStatusAfter.shortcut,
      })
        .then(this.onUpdateSuccess)
        .catch(this.onUpdateFail);
    },
    onUpdateSuccess() {
      this.$toast.show(s__('SetStatusModal|Status updated'));
      this.closeModal();
      window.location.reload();
    },
    onUpdateFail() {
      createFlash({
        message: s__(
          "SetStatusModal|Sorry, we weren't able to set your status. Please try again later.",
        ),
      });

      this.closeModal();
    },
    handleMessageInput(value) {
      this.message = value;
    },
    handleEmojiClick(emoji) {
      this.emoji = emoji;
    },
    handleClearStatusAfterClick(after) {
      this.clearStatusAfter = after;
    },
    handleAvailabilityInput(value) {
      this.availability = value;
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  actionPrimary: { text: s__('SetStatusModal|Set status') },
  actionSecondary: { text: s__('SetStatusModal|Remove status') },
};
</script>

<template>
  <gl-modal
    :title="s__('SetStatusModal|Set a status')"
    :modal-id="modalId"
    :action-primary="$options.actionPrimary"
    :action-secondary="$options.actionSecondary"
    modal-class="set-user-status-modal"
    @primary="setStatus"
    @secondary="removeStatus"
  >
    <set-status-form
      :default-emoji="defaultEmoji"
      :emoji="emoji"
      :message="message"
      :availability="availability"
      :clear-status-after="clearStatusAfter"
      :current-clear-status-after="currentClearStatusAfter"
      @message-input="handleMessageInput"
      @emoji-click="handleEmojiClick"
      @clear-status-after-click="handleClearStatusAfterClick"
      @availability-input="handleAvailabilityInput"
    />
  </gl-modal>
</template>
