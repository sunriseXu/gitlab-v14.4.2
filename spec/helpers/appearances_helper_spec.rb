# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppearancesHelper do
  before do
    user = create(:user)
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.current_appearance' do
    it 'memoizes empty appearance' do
      expect(Appearance).to receive(:current).once

      2.times { helper.current_appearance }
    end

    it 'memoizes custom appearance' do
      create(:appearance)

      expect(Appearance).to receive(:current).once.and_call_original

      2.times { helper.current_appearance }
    end
  end

  describe '#header_message' do
    it 'returns nil when header message field is not set' do
      create(:appearance)

      expect(helper.header_message).to be_nil
    end

    context 'when header message is set' do
      it 'includes current message' do
        message = "Foo bar"
        create(:appearance, header_message: message)

        expect(helper.header_message).to include(message)
      end
    end
  end

  describe '#footer_message' do
    it 'returns nil when footer message field is not set' do
      create(:appearance)

      expect(helper.footer_message).to be_nil
    end

    context 'when footer message is set' do
      it 'includes current message' do
        message = "Foo bar"
        create(:appearance, footer_message: message)

        expect(helper.footer_message).to include(message)
      end
    end
  end

  describe '#brand_image' do
    let!(:appearance) { create(:appearance, :with_logo) }

    context 'when there is a logo' do
      it 'returns a path' do
        expect(helper.brand_image).to match(%r(img data-src="/uploads/-/system/appearance/.*png))
      end
    end

    context 'when there is a logo but no associated upload' do
      before do
        # Legacy attachments were not tracked in the uploads table
        appearance.logo.upload.destroy!
        appearance.reload
      end

      it 'falls back to using the original path' do
        expect(helper.brand_image).to match(%r(img data-src="/uploads/-/system/appearance/.*png))
      end
    end
  end

  describe '#brand_header_logo' do
    let(:options) { {} }

    subject do
      helper.brand_header_logo(options)
    end

    context 'with header logo' do
      let!(:appearance) { create(:appearance, :with_header_logo) }

      it 'renders image tag' do
        expect(helper).to receive(:image_tag).with(appearance.header_logo_path, class: 'brand-header-logo')

        subject
      end
    end

    context 'with add_gitlab_white_text option' do
      let(:options) { { add_gitlab_white_text: true } }

      it 'renders shared/logo_with_white_text partial' do
        expect(helper).to receive(:render).with(partial: 'shared/logo_with_white_text', formats: :svg)

        subject
      end
    end

    context 'with add_gitlab_black_text option' do
      let(:options) { { add_gitlab_black_text: true } }

      it 'renders shared/logo_with_black_text partial' do
        expect(helper).to receive(:render).with(partial: 'shared/logo_with_black_text', formats: :svg)

        subject
      end
    end

    it 'renders shared/logo by default' do
      expect(helper).to receive(:render).with(partial: 'shared/logo', formats: :svg)

      subject
    end
  end

  describe '#brand_title' do
    it 'returns the default title when no appearance is present' do
      allow(helper).to receive(:current_appearance).and_return(nil)

      expect(helper.brand_title).to eq(helper.default_brand_title)
    end
  end
end
