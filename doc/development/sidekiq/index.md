---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq guides

We use [Sidekiq](https://github.com/mperham/sidekiq) as our background
job processor. These guides are for writing jobs that will work well on
GitLab.com and be consistent with our existing worker classes. For
information on administering GitLab, see [configuring Sidekiq](../../administration/sidekiq/index.md).

There are pages with additional detail on the following topics:

1. [Compatibility across updates](compatibility_across_updates.md)
1. [Job idempotency and job deduplication](idempotent_jobs.md)
1. [Limited capacity worker: continuously performing work with a specified concurrency](limited_capacity_worker.md)
1. [Logging](logging.md)
1. [Worker attributes](worker_attributes.md)
    1. **Job urgency** specifies queuing and execution SLOs
    1. **Resource boundaries** and **external dependencies** for describing the workload
    1. **Feature categorization**
    1. **Database load balancing**

## ApplicationWorker

All workers should include `ApplicationWorker` instead of `Sidekiq::Worker`,
which adds some convenience methods and automatically sets the queue based on
the [routing rules](../../administration/sidekiq/extra_sidekiq_routing.md#queue-routing-rules).

## Retries

Sidekiq defaults to using [25 retries](https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry),
with back-off between each retry. 25 retries means that the last retry
would happen around three weeks after the first attempt (assuming all 24
prior retries failed).

For most workers - especially [idempotent workers](idempotent_jobs.md) -
the default of 25 retries is more than sufficient. Many of our older
workers declare 3 retries, which used to be the default within the
GitLab application. 3 retries happen over the course of a couple of
minutes, so the jobs are prone to failing completely.

A lower retry count may be applicable if any of the below apply:

1. The worker contacts an external service and we do not provide
   guarantees on delivery. For example, webhooks.
1. The worker is not idempotent and running it multiple times could
   leave the system in an inconsistent state. For example, a worker that
   posts a system note and then performs an action: if the second step
   fails and the worker retries, the system note will be posted again.
1. The worker is a cronjob that runs frequently. For example, if a cron
   job runs every hour, then we don't need to retry beyond an hour
   because we don't need two of the same job running at once.

Each retry for a worker is counted as a failure in our metrics. A worker
which always fails 9 times and succeeds on the 10th would have a 90%
error rate.

## Sidekiq Queues

Previously, each worker had its own queue, which was automatically set based on the
worker class name. For a worker named `ProcessSomethingWorker`, the queue name
would be `process_something`. You can now route workers to a specific queue using
[queue routing rules](../../administration/sidekiq/extra_sidekiq_routing.md#queue-routing-rules).
In GDK, new workers are routed to a queue named `default`.

If you're not sure what queue a worker uses,
you can find it using `SomeWorker.queue`. There is almost never a reason to
manually override the queue name using `sidekiq_options queue: :some_queue`.

After adding a new worker, run `bin/rake
gitlab:sidekiq:all_queues_yml:generate` to regenerate
`app/workers/all_queues.yml` or `ee/app/workers/all_queues.yml` so that
it can be picked up by
[`sidekiq-cluster`](../../administration/sidekiq/extra_sidekiq_processes.md)
in installations that don't use routing rules. To learn more about potential changes,
read [Use routing rules by default and deprecate queue selectors for self-managed](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/596).

Additionally, run
`bin/rake gitlab:sidekiq:sidekiq_queues_yml:generate` to regenerate
`config/sidekiq_queues.yml`.

## Queue Namespaces

While different workers cannot share a queue, they can share a queue namespace.

Defining a queue namespace for a worker makes it possible to start a Sidekiq
process that automatically handles jobs for all workers in that namespace,
without needing to explicitly list all their queue names. If, for example, all
workers that are managed by `sidekiq-cron` use the `cronjob` queue namespace, we
can spin up a Sidekiq process specifically for these kinds of scheduled jobs.
If a new worker using the `cronjob` namespace is added later on, the Sidekiq
process also picks up jobs for that worker (after having been restarted),
without the need to change any configuration.

A queue namespace can be set using the `queue_namespace` DSL class method:

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  queue_namespace :cronjob

  # ...
end
```

Behind the scenes, this sets `SomeScheduledTaskWorker.queue` to
`cronjob:some_scheduled_task`. Commonly used namespaces have their own
concern module that can easily be included into the worker class, and that may
set other Sidekiq options besides the queue namespace. `CronjobQueue`, for
example, sets the namespace, but also disables retries.

`bundle exec sidekiq` is namespace-aware, and listens on all
queues in a namespace (technically: all queues prefixed with the namespace name)
when a namespace is provided instead of a simple queue name in the `--queue`
(`-q`) option, or in the `:queues:` section in `config/sidekiq_queues.yml`.

Note that adding a worker to an existing namespace should be done with care, as
the extra jobs take resources away from jobs from workers that were already
there, if the resources available to the Sidekiq process handling the namespace
are not adjusted appropriately.

## Versioning

Version can be specified on each Sidekiq worker class.
This is then sent along when the job is created.

```ruby
class FooWorker
  include ApplicationWorker

  version 2

  def perform(*args)
    if job_version == 2
      foo = args.first['foo']
    else
      foo = args.first
    end
  end
end
```

Under this schema, any worker is expected to be able to handle any job that was
enqueued by an older version of that worker. This means that when changing the
arguments a worker takes, you must increment the `version` (or set `version 1`
if this is the first time a worker's arguments are changing), but also make sure
that the worker is still able to handle jobs that were queued with any earlier
version of the arguments. From the worker's `perform` method, you can read
`self.job_version` if you want to specifically branch on job version, or you
can read the number or type of provided arguments.

## Job size

GitLab stores Sidekiq jobs and their arguments in Redis. To avoid
excessive memory usage, we compress the arguments of Sidekiq jobs
if their original size is bigger than 100KB.

After compression, if their size still exceeds 5MB, it raises an
[`ExceedLimitError`](https://gitlab.com/gitlab-org/gitlab/-/blob/f3dd89e5e510ea04b43ffdcb58587d8f78a8d77c/lib/gitlab/sidekiq_middleware/size_limiter/exceed_limit_error.rb#L8)
error when scheduling the job.

If this happens, rely on other means of making the data
available in Sidekiq. There are possible workarounds such as:

- Rebuild the data in Sidekiq with data loaded from the database or
  elsewhere.
- Store the data in [object storage](../file_storage.md#object-storage)
  before scheduling the job, and retrieve it inside the job.

## Job weights

Some jobs have a weight declared. This is only used when running Sidekiq
in the default execution mode - using
[`sidekiq-cluster`](../../administration/sidekiq/extra_sidekiq_processes.md)
does not account for weights.

As we are [moving towards using `sidekiq-cluster` in Free](https://gitlab.com/gitlab-org/gitlab/-/issues/34396), newly-added
workers do not need to have weights specified. They can use the
default weight, which is 1.

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.
