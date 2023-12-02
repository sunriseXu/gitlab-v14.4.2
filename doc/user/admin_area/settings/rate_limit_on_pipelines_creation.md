---
type: reference
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rate limits on pipeline creation **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) in GitLab 15.0.

You can set a limit so that users and processes can't request more than a certain number of pipelines each minute. This limit can help save resources and improve stability.

For example, if you set a limit of `10`, and `11` requests are sent to the [trigger API](../../../ci/triggers/index.md) within one minute,
the eleventh request is blocked. Access to the endpoint is allowed again after one minute.

This limit is:

- Applied independently per project, user, and commit.
- Not applied per IP address.
- Disabled by default.

Requests that exceed the limit are logged in the `application_json.log` file.

## Set a pipeline request limit

To limit the number of pipeline requests:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Pipelines Rate Limits**.
1. Under **Max requests per minute**, enter a value greater than `0`.
1. Select **Save changes**.
1. Enable `ci_enforce_throttle_pipelines_creation` feature flag to enable the rate limit.
