# frozen_string_literal: true

RSpec.shared_examples 'issuable supports timelog creation service' do
  shared_examples 'success_response' do
    it 'sucessfully saves the timelog' do
      is_expected.to be_success

      timelog = subject.payload[:timelog]

      expect(timelog).to be_persisted
      expect(timelog.time_spent).to eq(time_spent)
      expect(timelog.spent_at).to eq('Fri, 08 Jul 2022 00:00:00.000000000 UTC +00:00')
      expect(timelog.summary).to eq(summary)
      expect(timelog.issuable).to eq(issuable)
    end
  end

  context 'when the user does not have permission' do
    let(:user) { create(:user) }

    it 'returns an error' do
      is_expected.to be_error

      expect(subject.message).to eq(
        "#{issuable.base_class_name} doesn't exist or you don't have permission to add timelog to it.")
      expect(subject.http_status).to eq(404)
    end
  end

  context 'when the user has permissions' do
    let(:user) { author }

    before do
      users_container.add_reporter(user)
    end

    context 'when the timelog save fails' do
      before do
        allow_next_instance_of(Timelog) do |timelog|
          allow(timelog).to receive(:save).and_return(false)
        end
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Failed to save timelog')
      end
    end

    context 'when the creation completes sucessfully' do
      it_behaves_like 'success_response'
    end
  end
end

RSpec.shared_examples 'issuable does not support timelog creation service' do
  shared_examples 'error_response' do
    it 'returns an error' do
      is_expected.to be_error

      issuable_type = if issuable.nil?
                        'Issuable'
                      else
                        issuable.base_class_name
                      end

      expect(subject.message).to eq(
        "#{issuable_type} doesn't exist or you don't have permission to add timelog to it."
      )
      expect(subject.http_status).to eq(404)
    end
  end

  context 'when the user does not have permission' do
    let(:user) { create(:user) }

    it_behaves_like 'error_response'
  end

  context 'when the user has permissions' do
    let(:user) { author }

    before do
      users_container.add_reporter(user)
    end

    it_behaves_like 'error_response'
  end
end
