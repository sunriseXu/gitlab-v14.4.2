---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Plan limits API **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54232) in GitLab 13.10.

The plan limits API allows you to maintain the application limits for the existing subscription plans.

The existing plans depend on the GitLab edition. In the Community Edition, only the plan `default`
is available. In the Enterprise Edition, additional plans are available as well.

Administrator access is required to use this API.

## Get current plan limits

List the current limits of a plan on the GitLab instance.

```plaintext
GET /application/plan_limits
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | no       | Name of the plan to get the limits from. Default: `default`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits"
```

Example response:

```json
{
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_active_pipelines": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "conan_max_file_size": 3221225472,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824,
  "storage_size_limit": 15000
}
```

## Change plan limits

Modify the limits of a plan on the GitLab instance.

```plaintext
PUT /application/plan_limits
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | yes      | Name of the plan to update. |
| `ci_pipeline_size`                | integer | no       | Maximum number of jobs in a single pipeline. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_active_jobs`                  | integer | no       | Total number of jobs in currently active pipelines. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_active_pipelines`             | integer | no       | Maximum number of active pipelines per project. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_project_subscriptions`        | integer | no       | Maximum number of pipeline subscriptions to and from a project. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_pipeline_schedules`           | integer | no       | Maximum number of pipeline schedules. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_needs_size_limit`             | integer | no       | Maximum number of [DAG](../ci/directed_acyclic_graph/index.md) dependencies that a job can have. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_registered_group_runners`     | integer | no       | Maximum number of runners registered per group. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_registered_project_runners`   | integer | no       | Maximum number of runners registered per project. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `conan_max_file_size`             | integer | no       | Maximum Conan package file size in bytes. |
| `generic_packages_max_file_size`  | integer | no       | Maximum generic package file size in bytes. |
| `helm_max_file_size`              | integer | no       | Maximum Helm chart file size in bytes. |
| `maven_max_file_size`             | integer | no       | Maximum Maven package file size in bytes. |
| `npm_max_file_size`               | integer | no       | Maximum NPM package file size in bytes. |
| `nuget_max_file_size`             | integer | no       | Maximum NuGet package file size in bytes. |
| `pypi_max_file_size`              | integer | no       | Maximum PyPI package file size in bytes. |
| `terraform_module_max_file_size`  | integer | no       | Maximum Terraform Module package file size in bytes. |
| `storage_size_limit`              | integer | no       | Maximum storage size for the root namespace in megabytes. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

Example response:

```json
{
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_active_pipelines": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "conan_max_file_size": 3221225472,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```
