#!/usr/bin/env ruby
# frozen_string_literal: true

# In spec/scripts/setup/find_jh_branch_spec.rb we completely stub it
require 'gitlab' unless Object.const_defined?(:Gitlab)

require_relative '../api/default_options'

class FindJhBranch
  JH_DEFAULT_BRANCH = 'main-jh'
  JH_PROJECT_PATH = 'gitlab-org/gitlab-jh-mirrors/gitlab'
  BranchNotFound = Class.new(RuntimeError)

  def run
    return JH_DEFAULT_BRANCH unless merge_request?

    jh_merge_request_ref_name ||
      default_branch_merge_request_ref_name ||
      stable_branch_merge_request_ref_name ||
      default_branch_for_non_stable
  end

  private

  def merge_request?
    !!merge_request_id
  end

  def jh_merge_request_ref_name
    branch_exist?(JH_PROJECT_PATH, jh_ref_name) && jh_ref_name
  end

  def default_branch_merge_request_ref_name
    target_default_branch? && JH_DEFAULT_BRANCH
  end

  def stable_branch_merge_request_ref_name
    target_stable_branch? && begin
      jh_stable_branch_name = merge_request.target_branch.sub(/\-ee\z/, '-jh')

      branch_exist?(JH_PROJECT_PATH, jh_stable_branch_name) &&
        jh_stable_branch_name
    end
  end

  def default_branch_for_non_stable
    if target_stable_branch?
      raise(BranchNotFound, "Cannot find a suitable JH branch")
    else
      JH_DEFAULT_BRANCH
    end
  end

  def branch_exist?(project_path, branch_name)
    !!gitlab.branch(project_path, branch_name)
  rescue Gitlab::Error::NotFound
    false
  end

  def target_default_branch?
    merge_request.target_branch == default_branch
  end

  def target_stable_branch?
    merge_request.target_branch.match?(/\A(?:\d+\-)+\d+\-stable\-ee\z/)
  end

  def ref_name
    ENV['CI_COMMIT_REF_NAME']
  end

  def default_branch
    ENV['CI_DEFAULT_BRANCH']
  end

  def merge_request_project_id
    ENV['CI_MERGE_REQUEST_PROJECT_ID']
  end

  def merge_request_id
    ENV['CI_MERGE_REQUEST_IID']
  end

  def jh_ref_name
    "#{ref_name}-jh"
  end

  def merge_request
    @merge_request ||= gitlab.merge_request(merge_request_project_id, merge_request_id)
  end

  def gitlab
    @gitlab ||= Gitlab.client(
      endpoint: API::DEFAULT_OPTIONS[:endpoint],
      private_token: API::DEFAULT_OPTIONS[:api_token] || ''
    )
  end
end

if $0 == __FILE__
  puts FindJhBranch.new.run
end
