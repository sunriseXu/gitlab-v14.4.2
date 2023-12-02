---
stage: Platforms
group: Scalability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Application Service Level Indicators (SLIs)

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/525) in GitLab 14.4

It is possible to define [Service Level Indicators(SLIs)](https://en.wikipedia.org/wiki/Service_level_indicator)
directly in the Ruby codebase. This keeps the definition of operations
and their success close to the implementation and allows the people
building features to easily define how these features should be
monitored.

Defining an SLI causes 2
[Prometheus counters](https://prometheus.io/docs/concepts/metric_types/#counter)
to be emitted from the rails application:

- `gitlab_sli:<sli name>:total`: incremented for each operation.
- `gitlab_sli:<sli_name>:success_total`: incremented for successful
  operations.

## Existing SLIs

1. [`rails_request_apdex`](rails_request_apdex.md)
1. `global_search_apdex`

## Defining a new SLI

An SLI can be defined using the `Gitlab::Metrics::Sli::Apdex` or
`Gitlab::Metrics::Sli::ErrorRate` class. These work in broadly the same way, but
for clarity, they define different metric names:

1. `Gitlab::Metrics::Sli::Apdex.new('foo')` defines:
    1. `gitlab_sli:foo_apdex:total` for the total number of measurements.
    1. `gitlab_sli:foo_apdex:success_total` for the number of successful
       measurements.
1. `Gitlab::Metrics::Sli::ErrorRate.new('foo')` defines:
    1. `gitlab_sli:foo:total` for the total number of measurements.
    1. `gitlab_sli:foo:error_total` for the number of error
       measurements - as this is an error rate, it's more natural to talk about
       errors divided by the total.

As shown in this example, they can share a base name (`foo` in this example). We
recommend this when they refer to the same operation.

Before the first scrape, it is important to have
[initialized the SLI with all possible label-combinations](https://prometheus.io/docs/practices/instrumentation/#avoid-missing-metrics).
This avoid confusing results when using these counters in calculations.

To initialize an SLI, use the `.initialize_sli` class method, for
example:

```ruby
Gitlab::Metrics::Sli::Apdex.initialize_sli(:received_email, [
  {
    feature_category: :team_planning,
    email_type: :create_issue
  },
  {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  {
    feature_category: :code_review,
    email_type: :create_merge_request
  }
])
```

Metrics must be initialized before they get scraped for the first time.
This currently happens during the `on_master_start` [life-cycle event](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/cluster/lifecycle_events.rb).
Since this delays application readiness until metrics initialization returns, make sure the overhead
this adds is understood and acceptable.

## Tracking operations for an SLI

Tracking an operation in the newly defined SLI can be done like this:

```ruby
Gitlab::Metrics::Sli::Apdex[:received_email].increment(
  labels: {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  success: issue_created?
)
```

Calling `#increment` on this SLI will increment the total Prometheus counter

```prometheus
gitlab_sli:received_email_apdex:total{ feature_category='service_desk', email_type='service_desk' }
```

If the `success:` argument passed is truthy, then the success counter will also
be incremented:

```prometheus
gitlab_sli:received_email_apdex:success_total{ feature_category='service_desk', email_type='service_desk' }
```

For error rate SLIs, the equivalent argument is called `error:`:

```ruby
Gitlab::Metrics::Sli::ErrorRate[:merge].increment(
  labels: {
    merge_type: :fast_forward
  },
  error: !merge_success?
)
```

## Using the SLI in service monitoring and alerts

When the application is emitting metrics for a new SLI, they need
to be consumed from the [metrics catalog](https://gitlab.com/gitlab-com/runbooks/-/tree/master/metrics-catalog)
to result in alerts, and included in the error budget for stage
groups and GitLab.com's overall availability.

Start by adding the new SLI to the
[Application-SLI library](https://gitlab.com/gitlab-com/runbooks/-/blob/d109886dfd5170793eeb8de3d69aafd4a9da78f6/metrics-catalog/gitlab-slis/library.libsonnet#L4).
After that, add the following information:

- `name`: the name of the SLI as defined in code. For example
  `received_email`.
- `significantLabels`: an array of Prometheus labels that belong to the
  metrics. For example: `["email_type"]`. If the significant labels
  for the SLI include `feature_category`, the metrics will also
  feed into the
  [error budgets for stage groups](../stage_group_observability/index.md#error-budget).
- `featureCategory`: if the SLI applies to a single feature category,
  you can specify it statically through this field to feed the SLI
  into the error budgets for stage groups.
- `description`: a Markdown string explaining the SLI. It will
  be shown on dashboards and alerts.
- `kind`: the kind of indicator. For example `sliDefinition.apdexKind`.

When done, run `make generate` to generate recording rules for
the new SLI. This command creates recordings for all services
emitting these metrics aggregated over `significantLabels`.

Open up a merge request with these changes and request review from a Scalability
team member.

When these changes are merged, and the aggregations in
[Thanos](https://thanos.gitlab.net) recorded, query Thanos to see
the success ratio of the new aggregated metrics. For example:

```prometheus
sum by (environment, stage, type)(application_sli_aggregation:rails_request:apdex:success:rate_1h)
/
sum by (environment, stage, type)(application_sli_aggregation:rails_request:apdex:weight:score_1h)
```

This shows the success ratio, which can guide you to set an
appropriate SLO when adding this SLI to a service.

Then, add the SLI to the appropriate service
catalog file. For example, the [`web` service](https://gitlab.com/gitlab-com/runbooks/-/blob/2b7be37a006c236bd684a4e6a1fbf4c66158292a/metrics-catalog/services/web.jsonnet#L198):

```jsonnet
rails_requests:
  sliLibrary.get('rails_request_apdex')
    .generateServiceLevelIndicator({ job: 'gitlab-rails' })
```

To pass extra selectors and override properties of the SLI, see the
[service monitoring documentation](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/README.md).

SLIs with statically defined feature categories can already receive
alerts about the SLI in specified Slack channels. For more information, read the
[alert routing documentation](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/alert-routing.md).
In [this project](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/614)
we are extending this so alerts for SLIs with a `feature_category`
label in the source metrics can also be routed.

For any question, please don't hesitate to create an issue in
[the Scalability issue tracker](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues)
or come find us in
[#g_scalability](https://gitlab.slack.com/archives/CMMF8TKR9) on Slack.
