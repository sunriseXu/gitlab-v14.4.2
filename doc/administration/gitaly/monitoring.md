---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring Gitaly and Gitaly Cluster

You can use the available logs and [Prometheus metrics](../monitoring/prometheus/index.md) to
monitor Gitaly and Gitaly Cluster (Praefect).

Metric definitions are available:

- Directly from Prometheus `/metrics` endpoint configured for Gitaly.
- Using [Grafana Explore](https://grafana.com/docs/grafana/latest/explore/) on a
  Grafana instance configured against Prometheus.

## Monitor Gitaly rate limiting

Gitaly can be configured to limit requests based on:

- Concurrency of requests.
- A rate limit.

Monitor Gitaly request limiting with the `gitaly_requests_dropped_total` Prometheus metric. This metric provides a total count
of requests dropped due to request limiting. The `reason` label indicates why a request was dropped:

- `rate`, due to rate limiting.
- `max_size`, because the concurrency queue size was reached.
- `max_time`, because the request exceeded the maximum queue wait time as configured in Gitaly.

## Monitor Gitaly concurrency limiting

You can observe specific behavior of [concurrency-queued requests](configure_gitaly.md#limit-rpc-concurrency) using
the Gitaly logs and Prometheus:

- In the [Gitaly logs](../logs/index.md#gitaly-logs), look for the string (or structured log field)
  `acquire_ms`. Messages that have this field are reporting about the concurrency limiter.
- In Prometheus, look for the following metrics:
  - `gitaly_concurrency_limiting_in_progress` indicates how many concurrent requests are
    being processed.
  - `gitaly_concurrency_limiting_queued` indicates how many requests for an RPC for a given
    repository are waiting due to the concurrency limit being reached.
  - `gitaly_concurrency_limiting_acquiring_seconds` indicates how long a request has to
    wait due to concurrency limits before being processed.

## Monitor Gitaly cgroups

You can observe the status of [control groups (cgroups)](configure_gitaly.md#control-groups) using Prometheus:

- `gitaly_cgroups_reclaim_attempts_total`, a gauge for the total number of times
   there has been a memory relcaim attempt. This number resets each time a server is
   restarted.
- `gitaly_cgroups_cpu_usage`, a gauge that measures CPU usage per cgroup.
- `gitaly_cgroup_procs_total`, a gauge that measures the total number of
   processes Gitaly has spawned under the control of cgroups.

## `pack-objects` cache

The following [`pack-objects` cache](configure_gitaly.md#pack-objects-cache) metrics are available:

- `gitaly_pack_objects_cache_enabled`, a gauge set to `1` when the cache is enabled. Available
  labels: `dir` and `max_age`.
- `gitaly_pack_objects_cache_lookups_total`, a counter for cache lookups. Available label: `result`.
- `gitaly_pack_objects_generated_bytes_total`, a counter for the number of bytes written into the
  cache.
- `gitaly_pack_objects_served_bytes_total`, a counter for the number of bytes read from the cache.
- `gitaly_streamcache_filestore_disk_usage_bytes`, a gauge for the total size of cache files.
  Available label: `dir`.
- `gitaly_streamcache_index_entries`, a gauge for the number of entries in the cache. Available
  label: `dir`.

Some of these metrics start with `gitaly_streamcache` because they are generated by the
`streamcache` internal library package in Gitaly.

Example:

```plaintext
gitaly_pack_objects_cache_enabled{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache",max_age="300"} 1
gitaly_pack_objects_cache_lookups_total{result="hit"} 2
gitaly_pack_objects_cache_lookups_total{result="miss"} 1
gitaly_pack_objects_generated_bytes_total 2.618649e+07
gitaly_pack_objects_served_bytes_total 7.855947e+07
gitaly_streamcache_filestore_disk_usage_bytes{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 2.6200152e+07
gitaly_streamcache_filestore_removed_total{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
gitaly_streamcache_index_entries{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
```

## Useful queries

The following are useful queries for monitoring Gitaly:

- Use the following Prometheus query to observe the
  [type of connections](configure_gitaly.md#enable-tls-support) Gitaly is serving a production
  environment:

  ```prometheus
  sum(rate(gitaly_connections_total[5m])) by (type)
  ```

- Use the following Prometheus query to monitor the
  [authentication behavior](configure_gitaly.md#observe-type-of-gitaly-connections) of your GitLab
  installation:

  ```prometheus
  sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
  ```

  In a system where authentication is configured correctly and where you have live traffic, you
  see something like this:

  ```prometheus
  {enforced="true",status="ok"}  4424.985419441742
  ```

  There may also be other numbers with rate 0, but you only have to take note of the non-zero numbers.

  The only non-zero number should have `enforced="true",status="ok"`. If you have other non-zero
  numbers, something is wrong in your configuration.

  The `status="ok"` number reflects your current request rate. In the example above, Gitaly is
  handling about 4000 requests per second.

- Use the following Prometheus query to observe the [Git protocol versions](../git_protocol.md)
  being used in a production environment:

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```

## Monitor Gitaly Cluster

To monitor Gitaly Cluster (Praefect), you can use these Prometheus metrics. There are two separate metrics
endpoints from which metrics can be scraped:

- The default `/metrics` endpoint.
- `/db_metrics`, which contains metrics that require database queries.

### Default Prometheus `/metrics` endpoint

The following metrics are available from the `/metrics` endpoint:

- `gitaly_praefect_read_distribution`, a counter to track [distribution of reads](index.md#distributed-reads).
  It has two labels:

  - `virtual_storage`.
  - `storage`.

  They reflect configuration defined for this instance of Praefect.

- `gitaly_praefect_replication_latency_bucket`, a histogram measuring the amount of time it takes
  for replication to complete after the replication job starts. Available in GitLab 12.10 and later.
- `gitaly_praefect_replication_delay_bucket`, a histogram measuring how much time passes between
  when the replication job is created and when it starts. Available in GitLab 12.10 and later.
- `gitaly_praefect_node_latency_bucket`, a histogram measuring the latency in Gitaly returning
  health check information to Praefect. This indicates Praefect connection saturation. Available in
  GitLab 12.10 and later.
- `gitaly_praefect_connections_total`, the total number of connections to Praefect. [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4220) in GitLab 14.7.

To monitor [strong consistency](index.md#strong-consistency), you can use the following Prometheus metrics:

- `gitaly_praefect_transactions_total`, the number of transactions created and voted on.
- `gitaly_praefect_subtransactions_per_transaction_total`, the number of times nodes cast a vote for
  a single transaction. This can happen multiple times if multiple references are getting updated in
  a single transaction.
- `gitaly_praefect_voters_per_transaction_total`: the number of Gitaly nodes taking part in a
  transaction.
- `gitaly_praefect_transactions_delay_seconds`, the server-side delay introduced by waiting for the
  transaction to be committed.
- `gitaly_hook_transaction_voting_delay_seconds`, the client-side delay introduced by waiting for
  the transaction to be committed.

To monitor the number of repositories that have no healthy, up-to-date replicas:

- `gitaly_praefect_unavailable_repositories`

To monitor [repository verification](praefect.md#repository-verification), use the following Prometheus metrics:

- `gitaly_praefect_verification_queue_depth`, the total number of replicas pending verification. This
  metric is scraped from the database and is only available when Prometheus is scraping the database metrics.
- `gitaly_praefect_verification_jobs_dequeued_total`, the number of verification jobs picked up by the
  worker.
- `gitaly_praefect_verification_jobs_completed_total`, the number of verification jobs completed by the
  worker. The `result` label indicates the end result of the jobs:
  - `valid` indicates the expected replica existed on the storage.
  - `invalid` indicates the replica expected to exist did not exist on the storage.
  - `error` indicates the job failed and has to be retried.
- `gitaly_praefect_stale_verification_leases_released_total`, the number of stale verification leases
  released.

You can also monitor the [Praefect logs](../logs/index.md#praefect-logs).

### Database metrics `/db_metrics` endpoint

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/3286) in GitLab 14.5.

The following metrics are available from the `/db_metrics` endpoint:

- `gitaly_praefect_unavailable_repositories`, the number of repositories that have no healthy, up to date replicas.
- `gitaly_praefect_read_only_repositories`, the number of repositories in read-only mode in a virtual storage.
  This metric is available for backwards compatibility reasons. `gitaly_praefect_unavailable_repositories` is more
  accurate.
- `gitaly_praefect_replication_queue_depth`, the number of jobs in the replication queue.