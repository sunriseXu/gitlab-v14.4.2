# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Spamcheck::Client do
  include_context 'includes Spam constants'

  let(:endpoint) { 'grpc://grpc.test.url' }
  let_it_be(:user) { create(:user, organization: 'GitLab') }
  let(:verdict_value) { ::Spamcheck::SpamVerdict::Verdict::ALLOW }
  let(:error_value) { "" }

  let(:attribs_value) do
    extra_attributes = Google::Protobuf::Map.new(:string, :string)
    extra_attributes["monitorMode"] = "false"
    extra_attributes
  end

  let_it_be(:issue) { create(:issue, description: 'Test issue description') }
  let_it_be(:snippet) { create(:personal_snippet, :public, description: 'Test issue description') }

  let(:response) do
    verdict = ::Spamcheck::SpamVerdict.new
    verdict.verdict = verdict_value
    verdict.error = error_value
    verdict.extra_attributes = attribs_value
    verdict
  end

  subject { described_class.new.spam?(spammable: issue, user: user) }

  before do
    stub_application_setting(spam_check_endpoint_url: endpoint)
  end

  describe 'url scheme' do
    let(:stub) { double(:spamcheck_stub, check_for_spam_issue: response) }

    context 'is tls  ' do
      let(:endpoint) { 'tls://spamcheck.example.com' }

      it 'uses secure connection' do
        expect(Spamcheck::SpamcheckService::Stub).to receive(:new).with(endpoint.sub(%r{^tls://}, ''),
                                                                               instance_of(GRPC::Core::ChannelCredentials),
                                                                               anything).and_return(stub)
        subject
      end
    end

    context 'is grpc' do
      it 'uses insecure connection' do
        expect(Spamcheck::SpamcheckService::Stub).to receive(:new).with(endpoint.sub(%r{^grpc://}, ''),
                                                                               :this_channel_is_insecure,
                                                                               anything).and_return(stub)
        subject
      end
    end
  end

  shared_examples 'check for spam' do
    before do
      allow_next_instance_of(::Spamcheck::SpamcheckService::Stub) do |instance|
        allow(instance).to receive(:check_for_spam_issue).and_return(response)
        allow(instance).to receive(:check_for_spam_snippet).and_return(response)
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:verdict, :expected) do
      ::Spamcheck::SpamVerdict::Verdict::ALLOW                | Spam::SpamConstants::ALLOW
      ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW    | Spam::SpamConstants::CONDITIONAL_ALLOW
      ::Spamcheck::SpamVerdict::Verdict::DISALLOW             | Spam::SpamConstants::DISALLOW
      ::Spamcheck::SpamVerdict::Verdict::BLOCK                | Spam::SpamConstants::BLOCK_USER
      ::Spamcheck::SpamVerdict::Verdict::NOOP                 | Spam::SpamConstants::NOOP
    end

    with_them do
      let(:verdict_value) { verdict }

      it "returns expected spam constant" do
        expect(subject).to eq([expected, { "monitorMode" => "false" }, ""])
      end
    end

    it 'includes interceptors' do
      expect_next_instance_of(::Gitlab::Spamcheck::Client) do |client|
        expect(client).to receive(:interceptors).and_call_original
      end
      subject
    end
  end

  describe "#spam?", :aggregate_failures do
    describe 'issue' do
      subject { described_class.new.spam?(spammable: issue, user: user) }

      it_behaves_like "check for spam"
    end

    describe 'snippet' do
      subject { described_class.new.spam?(spammable: snippet, user: user, extra_features: { files: [{ path: "file.rb" }] }) }

      it_behaves_like "check for spam"
    end
  end

  describe "#build_protobuf", :aggregate_failures do
    it 'builds the expected issue protobuf object' do
      cxt = { action: :create }
      issue_pb, _ = described_class.new.send(:build_protobuf,
                                          spammable: issue, user: user,
                                          context: cxt, extra_features: {})
      expect(issue_pb.title).to eq issue.title
      expect(issue_pb.description).to eq issue.description
      expect(issue_pb.user_in_project).to be false
      expect(issue_pb.project.project_id).to eq issue.project_id
      expect(issue_pb.created_at).to eq timestamp_to_protobuf_timestamp(issue.created_at)
      expect(issue_pb.updated_at).to eq timestamp_to_protobuf_timestamp(issue.updated_at)
      expect(issue_pb.action).to be ::Spamcheck::Action.lookup(::Spamcheck::Action::CREATE)
      expect(issue_pb.user.username).to eq user.username
    end

    it 'builds the expected snippet protobuf object' do
      cxt = { action: :create }
      snippet_pb, _ = described_class.new.send(:build_protobuf,
                                          spammable: snippet, user: user,
                                          context: cxt, extra_features: { files: [{ path: 'first.rb' }, { path: 'second.rb' }] })
      expect(snippet_pb.title).to eq snippet.title
      expect(snippet_pb.description).to eq snippet.description
      expect(snippet_pb.created_at).to eq timestamp_to_protobuf_timestamp(snippet.created_at)
      expect(snippet_pb.updated_at).to eq timestamp_to_protobuf_timestamp(snippet.updated_at)
      expect(snippet_pb.action).to be ::Spamcheck::Action.lookup(::Spamcheck::Action::CREATE)
      expect(snippet_pb.user.username).to eq user.username
      expect(snippet_pb.user.username).to eq user.username
      expect(snippet_pb.files.first.path).to eq 'first.rb'
      expect(snippet_pb.files.last.path).to eq 'second.rb'
    end
  end

  describe '#build_user_protobuf', :aggregate_failures do
    it 'builds the expected protobuf object' do
      user_pb = described_class.new.send(:build_user_protobuf, user)
      expect(user_pb.username).to eq user.username
      expect(user_pb.org).to eq user.organization
      expect(user_pb.created_at).to eq timestamp_to_protobuf_timestamp(user.created_at)
      expect(user_pb.emails.count).to be 1
      expect(user_pb.emails.first.email).to eq user.email
      expect(user_pb.emails.first.verified).to eq user.confirmed?
    end

    context 'when user has multiple email addresses' do
      let(:secondary_email) { create(:email, :confirmed, user: user) }

      before do
        user.emails << secondary_email
      end

      it 'adds emails to the user pb object' do
        user_pb = described_class.new.send(:build_user_protobuf, user)
        expect(user_pb.emails.count).to eq 2
        expect(user_pb.emails.first.email).to eq user.email
        expect(user_pb.emails.first.verified).to eq user.confirmed?
        expect(user_pb.emails.last.email).to eq secondary_email.email
        expect(user_pb.emails.last.verified).to eq secondary_email.confirmed?
      end
    end
  end

  describe "#build_project_protobuf", :aggregate_failures do
    it 'builds the expected protobuf object' do
      project_pb = described_class.new.send(:build_project_protobuf, issue)
      expect(project_pb.project_id).to eq issue.project_id
      expect(project_pb.project_path).to eq issue.project.full_path
    end
  end

  describe "#get_spammable_mappings", :aggregate_failures do
    it 'is an expected spammable' do
      protobuf_class, _ = described_class.new.send(:get_spammable_mappings, issue)
      expect(protobuf_class).to eq ::Spamcheck::Issue
    end

    it 'is an unexpected spammable' do
      expect { described_class.new.send(:get_spammable_mappings, 'spam') }.to raise_error(
        ArgumentError, 'Not a spammable type: String'
      )
    end
  end

  private

  def timestamp_to_protobuf_timestamp(timestamp)
    Google::Protobuf::Timestamp.new(seconds: timestamp.to_time.to_i,
                                    nanos: timestamp.to_time.nsec)
  end
end
