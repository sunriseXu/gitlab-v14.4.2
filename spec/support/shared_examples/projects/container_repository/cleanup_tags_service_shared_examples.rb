# frozen_string_literal: true

RSpec.shared_examples 'handling invalid params' do |service_response_extra: {}, supports_caching: false|
  context 'when no params are specified' do
    let(:params) { {} }

    it_behaves_like 'not removing anything',
                    service_response_extra: service_response_extra,
                    supports_caching: supports_caching
  end

  context 'with invalid regular expressions' do
    shared_examples 'handling an invalid regex' do
      it 'keeps all tags' do
        expect(Projects::ContainerRepository::DeleteTagsService)
          .not_to receive(:new)
        expect_no_caching unless supports_caching

        subject
      end

      it { is_expected.to eq(status: :error, message: 'invalid regex') }

      it 'calls error tracking service' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).and_call_original

        subject
      end
    end

    context 'when name_regex_delete is invalid' do
      let(:params) { { 'name_regex_delete' => '*test*' } }

      it_behaves_like 'handling an invalid regex'
    end

    context 'when name_regex is invalid' do
      let(:params) { { 'name_regex' => '*test*' } }

      it_behaves_like 'handling an invalid regex'
    end

    context 'when name_regex_keep is invalid' do
      let(:params) { { 'name_regex_keep' => '*test*' } }

      it_behaves_like 'handling an invalid regex'
    end
  end
end

RSpec.shared_examples 'when regex matching everything is specified' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    { 'name_regex_delete' => '.*' }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: delete_expectations

  context 'with deprecated name_regex param' do
    let(:params) do
      { 'name_regex' => '.*' }
    end

    it_behaves_like 'removing the expected tags',
                    service_response_extra: service_response_extra,
                    supports_caching: supports_caching,
                    delete_expectations: delete_expectations
  end
end

RSpec.shared_examples 'when delete regex matching specific tags is used' do
  |service_response_extra: {}, supports_caching: false|
  let(:params) do
    { 'name_regex_delete' => 'C|D' }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: [%w[C D]]
end

RSpec.shared_examples 'when delete regex matching specific tags is used with overriding allow regex' do
  |service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex_delete' => 'C|D',
      'name_regex_keep' => 'C'
    }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: [%w[D]]

  context 'with name_regex_delete overriding deprecated name_regex' do
    let(:params) do
      {
        'name_regex' => 'C|D',
        'name_regex_delete' => 'D'
      }
    end

    it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: [%w[D]]
  end
end

RSpec.shared_examples 'with allow regex value' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'name_regex_keep' => 'B.*'
    }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: delete_expectations
end

RSpec.shared_examples 'when keeping only N tags' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    {
      'name_regex' => 'A|B.*|C',
      'keep_n' => 1
    }
  end

  it 'sorts tags by date' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    expect(service).to receive(:order_by_date_desc).at_least(:once).and_call_original

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end

RSpec.shared_examples 'when not keeping N tags' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    { 'name_regex' => 'A|B.*|C' }
  end

  it 'does not sort tags by date' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    expect(service).not_to receive(:order_by_date_desc)

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end

RSpec.shared_examples 'when removing keeping only 3' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    { 'name_regex_delete' => '.*',
      'keep_n' => 3 }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: delete_expectations
end

RSpec.shared_examples 'when removing older than 1 day' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'older_than' => '1 day'
    }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: delete_expectations
end

RSpec.shared_examples 'when combining all parameters' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'keep_n' => 1,
      'older_than' => '1 day'
    }
  end

  it_behaves_like 'removing the expected tags',
                  service_response_extra: service_response_extra,
                  supports_caching: supports_caching,
                  delete_expectations: delete_expectations
end

RSpec.shared_examples 'when running a container_expiration_policy' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  let(:user) { nil }

  context 'with valid container_expiration_policy param' do
    let(:params) do
      {
        'name_regex_delete' => '.*',
        'keep_n' => 1,
        'older_than' => '1 day',
        'container_expiration_policy' => true
      }
    end

    it 'removes the expected tags' do
      delete_expectations.each { |expectation| expect_delete(expectation, container_expiration_policy: true) }
      expect_no_caching unless supports_caching

      is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
    end
  end

  context 'without container_expiration_policy param' do
    let(:params) do
      {
        'name_regex_delete' => '.*',
        'keep_n' => 1,
        'older_than' => '1 day'
      }
    end

    it 'fails' do
      is_expected.to eq(status: :error, message: 'access denied')
    end
  end
end

RSpec.shared_examples 'not removing anything' do |service_response_extra: {}, supports_caching: false|
  it 'does not remove anything' do
    expect(Projects::ContainerRepository::DeleteTagsService).not_to receive(:new)
    expect_no_caching unless supports_caching

    is_expected.to eq(expected_service_response(deleted: []).merge(service_response_extra))
  end
end

RSpec.shared_examples 'removing the expected tags' do
  |service_response_extra: {}, supports_caching: false, delete_expectations:|
  it 'removes the expected tags' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end
