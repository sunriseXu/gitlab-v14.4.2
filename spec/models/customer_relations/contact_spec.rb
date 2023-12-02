# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contact, type: :model do
  let_it_be(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:issue_contacts) }
    it { is_expected.to have_many(:issues) }
  end

  describe 'validations' do
    subject { build(:contact) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }

    it { is_expected.to validate_length_of(:phone).is_at_most(32) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive.scoped_to(:group_id) }

    it_behaves_like 'an object with RFC3696 compliant email-formatted attributes', :email
  end

  describe '.reference_prefix' do
    it { expect(described_class.reference_prefix).to eq('[contact:') }
  end

  describe '.reference_prefix_quoted' do
    it { expect(described_class.reference_prefix_quoted).to eq('["contact:') }
  end

  describe '.reference_postfix' do
    it { expect(described_class.reference_postfix).to eq(']') }
  end

  describe '#root_group' do
    context 'when root group' do
      subject { build(:contact, group: group) }

      it { is_expected.to be_valid }
    end

    context 'when subgroup' do
      subject { build(:contact, group: create(:group, parent: group)) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#before_validation' do
    it 'strips leading and trailing whitespace' do
      contact = described_class.new(first_name: '  First  ', last_name: ' Last  ', phone: '  123456 ')
      contact.valid?

      expect(contact.first_name).to eq('First')
      expect(contact.last_name).to eq('Last')
      expect(contact.phone).to eq('123456')
    end
  end

  describe '#self.find_ids_by_emails' do
    let_it_be(:group_contacts) { create_list(:contact, 2, group: group) }
    let_it_be(:other_contacts) { create_list(:contact, 2) }

    it 'returns ids of contacts from group' do
      contact_ids = described_class.find_ids_by_emails(group, group_contacts.pluck(:email))

      expect(contact_ids).to match_array(group_contacts.pluck(:id))
    end

    it 'does not return ids of contacts from other groups' do
      contact_ids = described_class.find_ids_by_emails(group, other_contacts.pluck(:email))

      expect(contact_ids).to be_empty
    end

    it 'raises ArgumentError when called with too many emails' do
      too_many_emails = described_class::MAX_PLUCK + 1
      expect { described_class.find_ids_by_emails(group, Array(0..too_many_emails)) }.to raise_error(ArgumentError)
    end

    it 'finds contacts regardless of email casing' do
      new_contact = create(:contact, group: group, email: "UPPERCASE@example.com")
      emails = [group_contacts[0].email.downcase, group_contacts[1].email.upcase, new_contact.email]

      contact_ids = described_class.find_ids_by_emails(group, emails)

      expect(contact_ids).to contain_exactly(group_contacts[0].id, group_contacts[1].id, new_contact.id)
    end
  end

  describe '#self.exists_for_group?' do
    context 'with no contacts in group' do
      it 'returns false' do
        expect(described_class.exists_for_group?(group)).to be_falsey
      end
    end

    context 'with contacts in group' do
      it 'returns true' do
        create(:contact, group: group)

        expect(described_class.exists_for_group?(group)).to be_truthy
      end
    end
  end

  describe '#self.move_to_root_group' do
    let!(:old_root_group) { create(:group) }
    let!(:contacts) { create_list(:contact, 4, group: old_root_group) }
    let!(:project) { create(:project, group: old_root_group) }
    let!(:issue) { create(:issue, project: project) }
    let!(:issue_contact1) { create(:issue_customer_relations_contact, issue: issue, contact: contacts[0]) }
    let!(:issue_contact2) { create(:issue_customer_relations_contact, issue: issue, contact: contacts[1]) }
    let!(:new_root_group) { create(:group) }
    let!(:dupe_contact1) { create(:contact, group: new_root_group, email: contacts[1].email) }
    let!(:dupe_contact2) { create(:contact, group: new_root_group, email: contacts[3].email.upcase) }

    before do
      old_root_group.update!(parent: new_root_group)
      CustomerRelations::Contact.move_to_root_group(old_root_group)
    end

    it 'moves contacts with unique emails and deletes the rest' do
      expect(contacts[0].reload.group_id).to eq(new_root_group.id)
      expect(contacts[2].reload.group_id).to eq(new_root_group.id)
      expect { contacts[1].reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { contacts[3].reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'updates issue_contact.contact_id for dupes and leaves the rest untouched' do
      expect(issue_contact1.reload.contact_id).to eq(contacts[0].id)
      expect(issue_contact2.reload.contact_id).to eq(dupe_contact1.id)
    end
  end

  describe '.search' do
    let_it_be(:contact_a) do
      create(
        :contact,
        group: group,
        first_name: "ABC",
        last_name: "DEF",
        email: "ghi@test.com",
        description: "LMNO",
        state: "inactive"
      )
    end

    let_it_be(:contact_b) do
      create(
        :contact,
        group: group,
        first_name: "PQR",
        last_name: "STU",
        email: "vwx@test.com",
        description: "YZ",
        state: "active"
      )
    end

    subject(:found_contacts) { group.contacts.search(search_term) }

    context 'when search term is empty' do
      let(:search_term) { "" }

      it 'returns all group contacts' do
        expect(found_contacts).to contain_exactly(contact_a, contact_b)
      end
    end

    context 'when search term is not empty' do
      context 'when searching for first name ignoring casing' do
        let(:search_term) { "aBc" }

        it { is_expected.to contain_exactly(contact_a) }
      end

      context 'when searching for last name ignoring casing' do
        let(:search_term) { "StU" }

        it { is_expected.to contain_exactly(contact_b) }
      end

      context 'when searching for email' do
        let(:search_term) { "ghi" }

        it { is_expected.to contain_exactly(contact_a) }
      end

      context 'when searching description ignoring casing' do
        let(:search_term) { "Yz" }

        it { is_expected.to contain_exactly(contact_b) }
      end

      context 'when fuzzy searching for email and last name' do
        let(:search_term) { "s" }

        it { is_expected.to contain_exactly(contact_a, contact_b) }
      end
    end
  end

  describe '.search_by_state' do
    let_it_be(:contact_a) { create(:contact, group: group, state: "inactive") }
    let_it_be(:contact_b) { create(:contact, group: group, state: "active") }

    context 'when searching for contacts state' do
      it 'returns only inactive contacts' do
        expect(group.contacts.search_by_state(:inactive)).to contain_exactly(contact_a)
      end

      it 'returns only active contacts' do
        expect(group.contacts.search_by_state(:active)).to contain_exactly(contact_b)
      end
    end
  end

  describe '.counts_by_state' do
    before do
      create_list(:contact, 3, group: group)
      create_list(:contact, 2, group: group, state: 'inactive')
    end

    it 'returns correct contact counts' do
      counts = group.contacts.counts_by_state

      expect(counts['active']).to be(3)
      expect(counts['inactive']).to be(2)
    end
  end

  describe 'sorting' do
    let_it_be(:organization_a) { create(:organization, name: 'a') }
    let_it_be(:organization_b) { create(:organization, name: 'b') }
    let_it_be(:contact_a) { create(:contact, group: group, first_name: "c", last_name: "d") }
    let_it_be(:contact_b) do
      create(:contact,
        group: group,
        first_name: "a",
        last_name: "b",
        phone: "123",
        organization: organization_a)
    end

    let_it_be(:contact_c) do
      create(:contact,
        group: group,
        first_name: "e",
        last_name: "d",
        phone: "456",
        organization: organization_b)
    end

    describe '.sort_by_name' do
      it 'sorts them by last name then first name in ascending order' do
        expect(group.contacts.sort_by_name).to eq([contact_b, contact_a, contact_c])
      end
    end

    describe '.sort_by_organization' do
      it 'sorts them by organization in descending order' do
        expect(group.contacts.sort_by_organization(:desc)).to eq([contact_c, contact_b, contact_a])
      end
    end

    describe '.sort_by_field' do
      it 'sorts them by phone in ascending order' do
        expect(group.contacts.sort_by_field('phone', :asc)).to eq([contact_b, contact_c, contact_a])
      end
    end
  end
end
