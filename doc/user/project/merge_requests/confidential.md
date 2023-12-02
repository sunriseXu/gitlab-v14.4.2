---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge requests for confidential issues **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58583) in GitLab 12.1.

Merge requests in a public repository are also public, even when the merge
request is created for a [confidential issue](../issues/confidential_issues.md).
To avoid leaking confidential information when working on a confidential issue,
create your merge request from a private fork in the same namespace.

Roles are inherited from parent groups. If you create your private fork in the
same namespace (same group or subgroup) as the original (public) repository,
developers receive the same permissions in your fork. This inheritance ensures:

- Developer users have the needed permissions to view confidential issues and resolve them.
- You do not need grant individual users access to your fork.

The [security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer) at GitLab are available to read.

## Create a confidential merge request

Branches are public by default. To protect the confidentiality of your work, you
must create your branches and merge requests in the same namespace, but downstream
in a private fork. If you create your private fork in the same namespace as the
public repository, your fork inherits the permissions of the upstream public repository.
Users with the Developer role in the upstream public repository inherit those upstream
permissions in your downstream private fork without action by you. These users can
immediately push code to branches in your private fork to help fix the confidential issue.

WARNING:
Your private fork may expose confidential information, if you create it in a different
namespace than the upstream repository. The two namespaces may not contain the same users.

Prerequisites:

- You have the Owner or Maintainer role in the public repository, as you need one
  of these roles to [create a subgroup](../../group/subgroups/index.md).
- You have [forked](../repository/forking_workflow.md) the public repository.
- Your fork has a **Visibility level** of _Private_.

To create a confidential merge request:

1. Go to the confidential issue's page. Scroll below the issue description and
   select **Create confidential merge request**.
1. Select the item that meets your needs:
   - *To create both a branch and a merge request,* select
     **Create confidential merge request and branch**. Your merge request will
     target the default branch of your fork, *not* the default branch of the
     public upstream project.
   - *To create only a branch,* select **Create branch**.
1. Select a **Project** to use. These projects have merge requests enabled, and
   you have the Developer role (or greater) in them.
1. Provide a **Branch name**, and select a **Source (branch or tag)**. GitLab
   checks whether these branches are available in your private fork, because both
   branches must be available in your selected fork.
1. Select **Create**.

This merge request targets your private fork, not the public upstream project.
Your branch, merge requests, and commits remain in your private fork. This prevents
prematurely revealing confidential information.

Open a merge request
[from your fork to the upstream repository](../repository/forking_workflow.md#merging-upstream) when:

- You are satisfied the problem is resolved in your private fork.
- You are ready to make the confidential commits public.

## Related topics

- [Confidential issues](../issues/confidential_issues.md)
- [Make an epic confidential](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [Add an internal note](../../discussions/index.md#add-an-internal-note)
- [Security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer) at GitLab