<script>
import {
  GlButton,
  GlTooltipDirective,
  GlIcon,
  GlFormCheckbox,
  GlFormInput,
  GlFormInputGroup,
  GlDropdown,
  GlDropdownItem,
  GlSprintf,
  GlFormGroup,
  GlSafeHtmlDirective,
} from '@gitlab/ui';
import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import * as Emoji from '~/emoji';
import { s__ } from '~/locale';
import { TIME_RANGES_WITH_NEVER, AVAILABILITY_STATUS } from './constants';

export default {
  components: {
    GlButton,
    GlIcon,
    GlFormCheckbox,
    GlFormInput,
    GlFormInputGroup,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlFormGroup,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    defaultEmoji: {
      type: String,
      required: false,
      default: '',
    },
    emoji: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    availability: {
      type: Boolean,
      required: true,
    },
    clearStatusAfter: {
      type: Object,
      required: false,
      default: () => ({}),
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
      emojiTag: '',
    };
  },
  computed: {
    isCustomEmoji() {
      return this.emoji !== this.defaultEmoji;
    },
    isDirty() {
      return Boolean(this.message.length || this.isCustomEmoji);
    },
    noEmoji() {
      return this.emojiTag === '';
    },
  },
  mounted() {
    this.setupEmojiListAndAutocomplete();
  },
  methods: {
    async setupEmojiListAndAutocomplete() {
      const emojiAutocomplete = new GfmAutoComplete();
      emojiAutocomplete.setup($(this.$refs.statusMessageField.$el), { emojis: true });

      if (this.emoji) {
        this.emojiTag = Emoji.glEmojiTag(this.emoji);
      }
      this.defaultEmojiTag = Emoji.glEmojiTag(this.defaultEmoji);

      this.setDefaultEmoji();
    },
    setDefaultEmoji() {
      const { emojiTag } = this;
      const hasStatusMessage = Boolean(this.message.length);
      if (hasStatusMessage && emojiTag) {
        return;
      }

      if (hasStatusMessage) {
        this.emojiTag = this.defaultEmojiTag;
      } else if (emojiTag === this.defaultEmojiTag) {
        this.clearEmoji();
      }
    },
    handleEmojiClick(emoji) {
      this.$emit('emoji-click', emoji);

      this.emojiTag = Emoji.glEmojiTag(emoji);
    },
    clearEmoji() {
      if (this.emojiTag) {
        this.emojiTag = '';
      }
    },
    clearStatusInputs() {
      this.$emit('emoji-click', '');
      this.$emit('message-input', '');
      this.clearEmoji();
    },
  },
  TIME_RANGES_WITH_NEVER,
  AVAILABILITY_STATUS,
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  i18n: {
    statusMessagePlaceholder: s__(`SetStatusModal|What's your status?`),
    clearStatusButtonLabel: s__('SetStatusModal|Clear status'),
    availabilityCheckboxLabel: s__('SetStatusModal|Busy'),
    availabilityCheckboxHelpText: s__(
      'SetStatusModal|An indicator appears next to your name and avatar',
    ),
    clearStatusAfterDropdownLabel: s__('SetStatusModal|Clear status after'),
    clearStatusAfterMessage: s__('SetStatusModal|Your status resets on %{date}.'),
  },
};
</script>

<template>
  <div>
    <gl-form-input-group class="gl-mb-5">
      <gl-form-input
        ref="statusMessageField"
        :value="message"
        :placeholder="$options.i18n.statusMessagePlaceholder"
        @keyup="setDefaultEmoji"
        @input="$emit('message-input', $event)"
        @keyup.enter.prevent
      />
      <template #prepend>
        <emoji-picker
          dropdown-class="gl-h-full"
          toggle-class="btn emoji-menu-toggle-button gl-px-4! gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
          boundary="viewport"
          :right="false"
          @click="handleEmojiClick"
        >
          <template #button-content>
            <span
              v-if="noEmoji"
              class="no-emoji-placeholder position-relative"
              data-testid="no-emoji-placeholder"
            >
              <gl-icon name="slight-smile" class="award-control-icon-neutral" />
              <gl-icon name="smiley" class="award-control-icon-positive" />
              <gl-icon name="smile" class="award-control-icon-super-positive" />
            </span>
            <span v-else>
              <span
                v-safe-html:[$options.safeHtmlConfig]="emojiTag"
                data-testid="selected-emoji"
              ></span>
            </span>
          </template>
        </emoji-picker>
      </template>
      <template v-if="isDirty" #append>
        <gl-button
          v-gl-tooltip.bottom
          :title="$options.i18n.clearStatusButtonLabel"
          :aria-label="$options.i18n.clearStatusButtonLabel"
          icon="close"
          class="js-clear-user-status-button"
          @click="clearStatusInputs"
        />
      </template>
    </gl-form-input-group>

    <gl-form-checkbox
      :checked="availability"
      class="gl-mb-5"
      data-testid="user-availability-checkbox"
      @input="$emit('availability-input', $event)"
    >
      {{ $options.i18n.availabilityCheckboxLabel }}
      <template #help>
        {{ $options.i18n.availabilityCheckboxHelpText }}
      </template>
    </gl-form-checkbox>

    <gl-form-group :label="$options.i18n.clearStatusAfterDropdownLabel" class="gl-mb-0">
      <gl-dropdown
        block
        :text="clearStatusAfter.label"
        data-testid="clear-status-at-dropdown"
        toggle-class="gl-mb-0 gl-form-input-md"
      >
        <gl-dropdown-item
          v-for="after in $options.TIME_RANGES_WITH_NEVER"
          :key="after.name"
          :data-testid="after.name"
          @click="$emit('clear-status-after-click', after)"
          >{{ after.label }}</gl-dropdown-item
        >
      </gl-dropdown>

      <template v-if="currentClearStatusAfter.length" #description>
        <span data-testid="clear-status-at-message">
          <gl-sprintf :message="$options.i18n.clearStatusAfterMessage">
            <template #date>{{ currentClearStatusAfter }}</template>
          </gl-sprintf>
        </span>
      </template>
    </gl-form-group>
  </div>
</template>
