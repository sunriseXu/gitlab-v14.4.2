# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

RSpec.describe Gitlab::Utils::StrongMemoize do
  let(:klass) do
    strong_memoize_class = described_class

    Struct.new(:value) do
      include strong_memoize_class

      def self.method_added_list
        @method_added_list ||= []
      end

      def self.method_added(name)
        method_added_list << name
      end

      def method_name
        strong_memoize(:method_name) do
          trace << value
          value
        end
      end

      def method_name_attr
        trace << value
        value
      end
      strong_memoize_attr :method_name_attr

      strong_memoize_attr :different_method_name_attr, :different_member_name_attr
      def different_method_name_attr
        trace << value
        value
      end

      strong_memoize_attr :enabled?
      def enabled?
        true
      end

      def trace
        @trace ||= []
      end

      protected

      def private_method
      end
      private :private_method
      strong_memoize_attr :private_method

      public

      def protected_method
      end
      protected :protected_method
      strong_memoize_attr :protected_method

      private

      def public_method
      end
      public :public_method
      strong_memoize_attr :public_method
    end
  end

  subject(:object) { klass.new(value) }

  shared_examples 'caching the value' do
    it 'only calls the block once' do
      value0 = object.send(method_name)
      value1 = object.send(method_name)

      expect(value0).to eq(value)
      expect(value1).to eq(value)
      expect(object.trace).to contain_exactly(value)
    end

    it 'returns and defines the instance variable for the exact value' do
      returned_value = object.send(method_name)
      memoized_value = object.instance_variable_get(:"@#{member_name}")

      expect(returned_value).to eql(value)
      expect(memoized_value).to eql(value)
    end
  end

  describe '#strong_memoize' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value #{value}" do
        let(:value) { value }
        let(:method_name) { :method_name }
        let(:member_name) { :method_name }

        it_behaves_like 'caching the value'

        it 'raises exception for invalid type as key' do
          expect { object.strong_memoize(10) { 20 } }.to raise_error /Invalid type of '10'/
        end

        it 'raises exception for invalid characters in key' do
          expect { object.strong_memoize(:enabled?) { 20 } }
            .to raise_error /is not allowed as an instance variable name/
        end
      end
    end

    context "memory allocation", type: :benchmark do
      let(:value) { 'aaa' }

      before do
        object.method_name # warmup
      end

      [:method_name, "method_name"].each do |argument|
        context "for #{argument.class}" do
          it 'does allocate exactly one string when fetching value' do
            expect do
              object.strong_memoize(argument) { 10 }
            end.to perform_allocation(1)
          end

          it 'does allocate exactly one string when storing value' do
            object.clear_memoization(:method_name) # clear to force set

            expect do
              object.strong_memoize(argument) { 10 }
            end.to perform_allocation(1)
          end
        end
      end
    end
  end

  describe '#strong_memoized?' do
    let(:value) { :anything }

    subject { object.strong_memoized?(:method_name) }

    it 'returns false if the value is uncached' do
      is_expected.to be(false)
    end

    it 'returns true if the value is cached' do
      object.method_name

      is_expected.to be(true)
    end
  end

  describe '#clear_memoization' do
    let(:value) { 'mepmep' }

    it 'removes the instance variable' do
      object.method_name

      object.clear_memoization(:method_name)

      expect(object.instance_variable_defined?(:@method_name)).to be(false)
    end
  end

  describe '.strong_memoize_attr' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      let(:value) { value }

      context "memoized after method definition with value #{value}" do
        let(:method_name) { :method_name_attr }
        let(:member_name) { :method_name_attr }

        it_behaves_like 'caching the value'

        it 'calls the existing .method_added' do
          expect(klass.method_added_list).to include(:method_name_attr)
        end
      end

      context "memoized before method definition with different member name and value #{value}" do
        let(:method_name) { :different_method_name_attr }
        let(:member_name) { :different_member_name_attr }

        it_behaves_like 'caching the value'

        it 'calls the existing .method_added' do
          expect(klass.method_added_list).to include(:different_method_name_attr)
        end
      end

      context 'with valid method name' do
        let(:method_name) { :enabled? }

        context 'with invalid member name' do
          let(:member_name) { :enabled? }

          it 'is invalid' do
            expect { object.send(method_name) { value } }.to raise_error /is not allowed as an instance variable name/
          end
        end
      end
    end

    describe 'method visibility' do
      it 'sets private visibility' do
        expect(klass.private_instance_methods).to include(:private_method)
        expect(klass.protected_instance_methods).not_to include(:private_method)
        expect(klass.public_instance_methods).not_to include(:private_method)
      end

      it 'sets protected visibility' do
        expect(klass.private_instance_methods).not_to include(:protected_method)
        expect(klass.protected_instance_methods).to include(:protected_method)
        expect(klass.public_instance_methods).not_to include(:protected_method)
      end

      it 'sets public visibility' do
        expect(klass.private_instance_methods).not_to include(:public_method)
        expect(klass.protected_instance_methods).not_to include(:public_method)
        expect(klass.public_instance_methods).to include(:public_method)
      end
    end
  end
end
