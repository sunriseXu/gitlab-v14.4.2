---
stage: DevSecOps
group: Technical writing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Get started with GitLab application security **(ULTIMATE)**

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Adopting GitLab application security](https://www.youtube.com/watch?v=5QlxkiKR04k).

The following steps will help you get the most from GitLab application security tools. These steps are a recommended order of operations. You can choose to implement capabilities in a different order or omit features that do not apply to your specific needs.

1. Enable [Secret Detection](secret_detection/index.md) and [Dependency Scanning](dependency_scanning/index.md)
   to identify any leaked secrets and vulnerable packages in your codebase.

   - For all security scanners, enable them by updating your `[.gitlab-ci.yml](../../ci/yaml/gitlab_ci_yaml.md)` directly on your `default` branch. This creates a baseline scan of your `default` branch, which is necessary for
   feature branch scans to be compared against. This allows [merge requests](../project/merge_requests/index.md)
   to display only newly-introduced vulnerabilities. Otherwise, merge requests will display every
   vulnerability in the branch, regardless of whether it was introduced by a change in the branch.
   - If you are after simplicity, enable only Secret Detection first. It only has one analyzer,
   no build requirements, and relatively simple findings: is this a secret or not?
   - It is good practice to enable Dependency Scanning early so you can start identifying existing
   vulnerable packages in your codebase.
1. Let your team get comfortable with [vulnerability reports](vulnerability_report/index.md) and
   establish a vulnerability triage workflow.
1. Consider creating [labels](../project/labels.md) and [issue boards](../project/issue_board.md) to
   help manage issues created from vulnerabilities. Issue boards allow all stakeholders to have a
   common view of all issues and track remediation progress.
1. Use [scheduled pipelines](../../ci/pipelines/schedules.md#scheduled-pipelines) to regularly scan important branches such as `default` or those used for maintenance releases.
   - Running regular dependency and [container scans](container_scanning/index.md) will surface newly-discovered vulnerabilities that already exist in your repository.
   - Scheduled scans are most useful for projects or important branches with low development activity where pipeline scans are infrequent.
1. Create a [scan result policy](policies/index.md) to limit new vulnerabilities from being merged
   into your `default` branch.
1. Monitor the [Security Dashboard](security_dashboard/index.md) trends to gauge success in
   remediating existing vulnerabilities and preventing the introduction of new ones.
1. Enable other scan types such as [SAST](sast/index.md), [DAST](dast/index.md),
   [Fuzz testing](coverage_fuzzing/index.md), or [Container Scanning](container_scanning/index.md).
1. Use [Compliance Pipelines](../../user/project/settings/index.md#compliance-pipeline-configuration)
   or [Scan Execution Policies](policies/scan-execution-policies.md) to enforce required scan types
   and ensure separation of duties between security and engineering.
1. Consider enabling [Review Apps](../../development/testing_guide/review_apps.md) to allow for DAST
   and [Web API fuzzing](api_fuzzing/index.md) on ephemeral test environments.
1. Enable [operational container scanning](../../user/clusters/agent/vulnerabilities.md) to scan
   container images in your production cluster for security vulnerabilities.
