# frozen_string_literal: true

module QA
  module Resource
    class MergeRequest < Base
      attr_accessor :approval_rules,
                    :source_branch,
                    :target_new_branch,
                    :update_existing_file,
                    :assignee,
                    :milestone,
                    :labels,
                    :file_name,
                    :file_content

      attr_writer :no_preparation,
                  :wait_for_merge,
                  :template

      attributes :iid,
                 :title,
                 :description,
                 :merge_when_pipeline_succeeds,
                 :merge_status,
                 :state

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-merge-request'
          resource.initialize_with_readme = true
          resource.api_client = api_client
        end
      end

      attribute :target_branch do
        project.default_branch
      end

      attribute :target do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.add_files([{ 'file_path': "file-#{SecureRandom.hex(8)}.txt", 'content': 'MR init' }])
          resource.branch = target_branch

          resource.start_branch = project.default_branch if target_branch != project.default_branch
        end
      end

      attribute :source do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.branch = source_branch
          resource.start_branch = target_branch

          files = [{ 'file_path': file_name, 'content': file_content }]
          update_existing_file ? resource.update_files(files) : resource.add_files(files)
        end
      end

      def initialize
        @approval_rules = nil
        @title = 'QA test - merge request'
        @description = 'This is a test merge request'
        @source_branch = "qa-test-feature-#{SecureRandom.hex(8)}"
        @assignee = nil
        @milestone = nil
        @labels = []
        @file_name = "added_file-#{SecureRandom.hex(8)}.txt"
        @file_content = "File Added"
        @target_new_branch = true
        @update_existing_file = false
        @no_preparation = false
        @wait_for_merge = true
      end

      def fabricate!
        return fabricate_large_merge_request if large_setup?

        populate_target_and_source_if_required

        project.visit!
        Flow::MergeRequest.create_new(source_branch: source_branch)
        Page::MergeRequest::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description && !@template
          new_page.choose_milestone(@milestone) if @milestone
          new_page.assign_to_me if @assignee == 'me'
          labels.each do |label|
            new_page.select_label(label)
          end
          new_page.add_approval_rules(approval_rules) if approval_rules

          new_page.create_merge_request
        end
      end

      def fabricate_via_api!
        return fabricate_large_merge_request if large_setup?

        resource_web_url(api_get)
      rescue ResourceNotFoundError, NoValueError # rescue if iid not populated
        populate_target_and_source_if_required

        super
      end

      def api_merge_path
        "/projects/#{project.id}/merge_requests/#{iid}/merge"
      end

      def api_get_path
        "/projects/#{project.id}/merge_requests/#{iid}"
      end

      def api_post_path
        "/projects/#{project.id}/merge_requests"
      end

      def api_post_body
        {
          description: description,
          source_branch: source_branch,
          target_branch: target_branch,
          title: title
        }
      end

      def api_comments_path
        "#{api_get_path}/notes"
      end

      def merge_via_api!
        Support::Waiter.wait_until(sleep_interval: 1) do
          QA::Runtime::Logger.debug("Waiting until merge request with id '#{iid}' can be merged")

          reload!.merge_status == 'can_be_merged'
        end

        Support::Retrier.retry_on_exception do
          response = put(Runtime::API::Request.new(api_client, api_merge_path).url)

          unless response.code == HTTP_STATUS_OK
            raise ResourceUpdateFailedError, "Could not merge. Request returned (#{response.code}): `#{response}`."
          end

          result = parse_body(response)

          project.wait_for_merge(result[:title]) if @wait_for_merge

          result
        end
      end

      def fabricate_large_merge_request
        @project = Resource::ImportProject.fabricate_via_browser_ui!
        # Setting the name here, since otherwise some tests will look for an existing file in
        # the proejct without ever knowing what is in it.
        @file_name = "added_file-00000000.txt"
        @source_branch = "large_merge_request"
        visit("#{project.web_url}/-/merge_requests/1")
        current_url
      end

      # Get MR comments
      #
      # @return [Array]
      def comments(auto_paginate: false, attempts: 0)
        return parse_body(api_get_from(api_comments_path)) unless auto_paginate

        auto_paginated_response(
          Runtime::API::Request.new(api_client, api_comments_path, per_page: '100').url,
          attempts: attempts
        )
      end

      # Add mr comment
      #
      # @param [String] body
      # @return [Hash]
      def add_comment(body)
        api_post_to(api_comments_path, body: body)
      end

      # Return subset of fields for comparing merge requests
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.except(
          :id,
          :web_url,
          :project_id,
          :source_project_id,
          :target_project_id,
          :merge_status,
          # these can differ depending on user fetching mr
          :user,
          :subscribed,
          :first_contribution
        ).merge({ references: api_resource[:references].except(:full) })
      end

      private

      def large_setup?
        Runtime::Scenario.large_setup?
      rescue ArgumentError
        false
      end

      def transform_api_resource(api_resource)
        raise ResourceNotFoundError if api_resource.blank?

        super(api_resource)
      end

      # Create source and target and commits if necessary
      #
      # @return [void]
      def populate_target_and_source_if_required
        return if @no_preparation

        populate(:target) if create_target?
        populate(:source)
      end

      # Check if target needs to be created
      #
      # Return false if project was already initialized and mr target is default branch
      # Return false if target_new_branch is explicitly set to false
      #
      # @return [Boolean]
      def create_target?
        !(project.initialize_with_readme && target_branch == project.default_branch) && target_new_branch
      end
    end
  end
end
