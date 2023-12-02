---
type: reference
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting Elasticsearch **(PREMIUM SELF)**

Use the following information to troubleshoot Elasticsearch issues.

## Set configurations in the Rails console

See [Starting a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).

### List attributes

To list all available attributes:

1. Open the Rails console (`gitlab rails c`).
1. Run the following command:

```ruby
ApplicationSetting.last.attributes
```

The output contains all the settings available in [Elasticsearch integration](../../integration/advanced_search/elasticsearch.md), such as `elasticsearch_indexing`, `elasticsearch_url`, `elasticsearch_replicas`, and `elasticsearch_pause_indexing`.

### Set attributes

To set an Elasticsearch integration setting, run a command like:

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

### Get attributes

To check if the settings have been set in [Elasticsearch integration](../../integration/advanced_search/elasticsearch.md) or in the Rails console, run a command like:

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

### Change the password

To change the Elasticsearch password, run the following commands:

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current Elasticsearch URL
es_url.elasticsearch_url

# Set the Elasticsearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```

## View logs

One of the most valuable tools for identifying issues with the Elasticsearch
integration are logs. The most relevant logs for this integration are:

1. [`sidekiq.log`](../../administration/logs/index.md#sidekiqlog) - All of the
   indexing happens in Sidekiq, so much of the relevant logs for the
   Elasticsearch integration can be found in this file.
1. [`elasticsearch.log`](../../administration/logs/index.md#elasticsearchlog) - There
   are additional logs specific to Elasticsearch that are sent to this file
   that may contain useful diagnostic information about searching,
   indexing or migrations.

Here are some common pitfalls and how to overcome them.

## Common terminology

- **Lucene**: A full-text search library written in Java.
- **Near real time (NRT)**: Refers to the slight latency from the time to index a
  document to the time when it becomes searchable.
- **Cluster**: A collection of one or more nodes that work together to hold all
  the data, providing indexing and search capabilities.
- **Node**: A single server that works as part of a cluster.
- **Index**: A collection of documents that have somewhat similar characteristics.
- **Document**: A basic unit of information that can be indexed.
- **Shards**: Fully-functional and independent subdivisions of indices. Each shard is actually
  a Lucene index.
- **Replicas**: Failover mechanisms that duplicate indices.

## How can I verify that my GitLab instance is using Elasticsearch?

There are a couple of ways to achieve that:

- Whenever you perform a search there is a link on the search results page
  in the top right hand corner saying "Advanced search functionality is enabled".
  This is always correctly identifying whether the current project/namespace
  being searched is using Elasticsearch.

- From the Admin Area under **Settings > Advanced Search** check that the
  Advanced Search settings are checked.

  Those same settings there can be obtained from the Rails console if necessary:

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- Confirm searches use Elasticsearch by accessing the
  [rails console](../../administration/operations/rails_console.md) and running the following
  commands:

  ```rails
  u = User.find_by_email('email_of_user_doing_search')
  s = SearchService.new(u, {:search => 'search_term'})
  pp s.search_objects.class
  ```

  The output from the last command is the key here. If it shows:

  - `ActiveRecord::Relation`, **it is not** using Elasticsearch.
  - `Kaminari::PaginatableArray`, **it is** using Elasticsearch.

- If Elasticsearch is limited to specific namespaces and you need to know if
  Elasticsearch is being used for a specific project or namespace, you can use
  the Rails console:

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## Troubleshooting indexing

Troubleshooting indexing issues can be tricky. It can pretty quickly go to either GitLab
support or your Elasticsearch administrator.

The best place to start is to determine if the issue is with creating an empty index.
If it is, check on the Elasticsearch side to determine if the `gitlab-production` (the
name for the GitLab index) exists. If it exists, manually delete it on the Elasticsearch
side and attempt to recreate it from the
[`recreate_index`](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)
Rake task.

If you still encounter issues, try creating an index manually on the Elasticsearch
instance. The details of the index aren't important here, as we want to test if indices
can be made. If the indices:

- Cannot be made, speak with your Elasticsearch administrator.
- Can be made, Escalate this to GitLab support.

If the issue is not with creating an empty index, the next step is to check for errors
during the indexing of projects. If errors do occur, they stem from either the indexing:

- On the GitLab side. You need to rectify those. If they are not
  something you are familiar with, contact GitLab support for guidance.
- Within the Elasticsearch instance itself. See if the error is [documented and has a fix](../../integration/advanced_search/elasticsearch_troubleshooting.md). If not, speak with your Elasticsearch administrator.

If the indexing process does not present errors, check the status of the indexed projects. You can do this via the following Rake tasks:

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) (shows the overall status)
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) (shows specific projects that are not indexed)

If:

- Everything is showing at 100%, escalate to GitLab support. This could be a potential
  bug/issue.
- You do see something not at 100%, attempt to reindex that project. To do this,
  run `sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`.

If reindexing the project shows:

- Errors on the GitLab side, escalate those to GitLab support.
- Elasticsearch errors or doesn't present any errors at all, reach out to your
  Elasticsearch administrator to check the instance.

### I updated GitLab and now I can't find anything

We continuously make updates to our indexing strategies and aim to support
newer versions of Elasticsearch. When indexing changes are made, it may
be necessary for you to [reindex](elasticsearch.md#zero-downtime-reindexing) after updating GitLab.

### I indexed all the repositories but I can't get any hits for my search term in the UI

Make sure you [indexed all the database data](elasticsearch.md#enable-advanced-search).

If there aren't any results (hits) in the UI search, check if you are seeing the same results via the rails console (`sudo gitlab-rails console`):

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

Beyond that, check via the [Elasticsearch Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) to see if the data shows up on the Elasticsearch side:

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

More [complex Elasticsearch API calls](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html) are also possible.

If the results:

- Sync up, please check that you are using [supported syntax](../../user/search/global_search/advanced_search_syntax.md). Note that Advanced Search does not support [exact substring matching](https://gitlab.com/gitlab-org/gitlab/-/issues/325234).
- Do not match up, this indicates a problem with the documents generated from the project. It is best to [re-index that project](../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project)

NOTE:
The above instructions are not to be used for scenarios that only index a [subset of namespaces](elasticsearch.md#limit-the-number-of-namespaces-and-projects-that-can-be-indexed).

See [Elasticsearch Index Scopes](elasticsearch.md#advanced-search-index-scopes) for more information on searching for specific types of data.

### I indexed all the repositories but then switched Elasticsearch servers and now I can't find anything

You must re-run all the Rake tasks to reindex the database, repositories, and wikis.

### The indexing process is taking a very long time

The more data present in your GitLab instance, the longer the indexing process takes.

### There are some projects that weren't indexed, but I don't know which ones

You can run `sudo gitlab-rake gitlab:elastic:projects_not_indexed` to display projects that aren't indexed.

### No new data is added to the Elasticsearch index when I push code

NOTE:
This was [fixed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35936) in GitLab 13.2 and the Rake task is not available for versions greater than that.

When performing the initial indexing of blobs, we lock all projects until the project finishes indexing. It could happen that an error during the process causes one or multiple projects to remain locked. To unlock them, run:

```shell
sudo gitlab-rake gitlab:elastic:clear_locked_projects
```

### Indexing fails with `error: elastic: Error 429 (Too Many Requests)`

If `ElasticCommitIndexerWorker` Sidekiq workers are failing with this error during indexing, it usually means that Elasticsearch is unable to keep up with the concurrency of indexing request. To address change the following settings:

- To decrease the indexing throughput you can decrease `Bulk request concurrency` (see [Advanced Search settings](elasticsearch.md#advanced-search-configuration)). This is set to `10` by default, but you change it to as low as 1 to reduce the number of concurrent indexing operations.
- If changing `Bulk request concurrency` didn't help, you can use the [queue selector](../../administration/sidekiq/extra_sidekiq_processes.md#queue-selector) option to [limit indexing jobs only to specific Sidekiq nodes](elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes), which should reduce the number of indexing requests.

### Indexing is very slow or fails with `rejected execution of coordinating operation` messages

Bulk requests getting rejected by the Elasticsearch nodes are likely due to load and lack of available memory.
Ensure that your Elasticsearch cluster meets the [system requirements](elasticsearch.md#system-requirements) and has enough resources
to perform bulk operations. See also the error ["429 (Too Many Requests)"](#indexing-fails-with-error-elastic-error-429-too-many-requests).

### Last resort to recreate an index

There may be cases where somehow data never got indexed and it's not in the
queue, or the index is somehow in a state where migrations just cannot
proceed. It is always best to try to troubleshoot the root cause of the problem
by [viewing the logs](#view-logs).

If there are no other options, then you always have the option of recreating the
entire index from scratch. If you have a small GitLab installation, this can
sometimes be a quick way to resolve a problem, but if you have a large GitLab
installation, then this might take a very long time to complete. Until the
index is fully recreated, your index does not serve correct search results,
so you may want to disable **Search with Elasticsearch** while it is running.

If you are sure you've read the above caveats and want to proceed, then you
should run the following Rake task to recreate the entire index from scratch:

**For Omnibus installations**

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

**For installations from source**

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

### Troubleshooting performance

Troubleshooting performance can be difficult on Elasticsearch. There is a ton of tuning
that *can* be done, but the majority of this falls on shoulders of a skilled
Elasticsearch administrator.

Generally speaking, ensure:

- The Elasticsearch server **is not** running on the same node as GitLab.
- The Elasticsearch server have enough RAM and CPU cores.
- That sharding **is** being used.

Going into some more detail here, if Elasticsearch is running on the same server as GitLab, resource contention is **very** likely to occur. Ideally, Elasticsearch, which requires ample resources, should be running on its own server (maybe coupled with Logstash and Kibana).

When it comes to Elasticsearch, RAM is the key resource. Elasticsearch themselves recommend:

- **At least** 8 GB of RAM for a non-production instance.
- **At least** 16 GB of RAM for a production instance.
- Ideally, 64 GB of RAM.

For CPU, Elasticsearch recommends at least 2 CPU cores, but Elasticsearch states common
setups use up to 8 cores. For more details on server specs, check out
[Elasticsearch's hardware guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html).

Beyond the obvious, sharding comes into play. Sharding is a core part of Elasticsearch.
It allows for horizontal scaling of indices, which is helpful when you are dealing with
a large amount of data.

With the way GitLab does indexing, there is a **huge** amount of documents being
indexed. By utilizing sharding, you can speed up Elasticsearch's ability to locate
data, since each shard is a Lucene index.

If you are not using sharding, you are likely to hit issues when you start using
Elasticsearch in a production environment.

Keep in mind that an index with only one shard has **no scale factor** and will
likely encounter issues when called upon with some frequency.

If you need to know how many shards, read
[Elasticsearch's documentation on capacity planning](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html),
as the answer is not straight forward.

The easiest way to determine if sharding is in use is to check the output of the
[Elasticsearch Health API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html):

- Red means the cluster is down.
- Yellow means it is up with no sharding/replication.
- Green means it is healthy (up, sharding, replicating).

For production use, it should always be green.

Beyond these steps, you get into some of the more complicated things to check,
such as merges and caching. These can get complicated and it takes some time to
learn them, so it is best to escalate/pair with an Elasticsearch expert if you need to
dig further into these.

Feel free to reach out to GitLab support, but this is likely to be something a skilled
Elasticsearch administrator has more experience with.

## Issues with migrations

Please ensure you've read about [Elasticsearch Migrations](../advanced_search/elasticsearch.md#advanced-search-migrations).

If there is a halted migration and your [`elasticsearch.log`](../../administration/logs/index.md#elasticsearchlog) file contain errors, this could potentially be a bug/issue. Escalate to GitLab support if retrying migrations does not succeed.

## `Can't specify parent if no parent field has been configured` error

If you enabled Elasticsearch before GitLab 8.12 and have not rebuilt indices, you get
exceptions in lots of different cases:

```plaintext
Elasticsearch::Transport::Transport::Errors::BadRequest([400] {
    "error": {
        "root_cause": [{
            "type": "illegal_argument_exception",
            "reason": "Can't specify parent if no parent field has been configured"
        }],
        "type": "illegal_argument_exception",
        "reason": "Can't specify parent if no parent field has been configured"
    },
    "status": 400
}):
```

This is because we changed the index mapping in GitLab 8.12 and the old indices should be removed and built from scratch again,
see details in the [update guide](../../update/upgrading_from_source.md).

## `Elasticsearch::Transport::Transport::Errors::BadRequest`

If you have this exception (just like in the case above but the actual message is different) please check if you have the correct Elasticsearch version and you met the other [requirements](elasticsearch.md#system-requirements).
There is also an easy way to check it automatically with `sudo gitlab-rake gitlab:check` command.

## `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge`

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

This exception is seen when your Elasticsearch cluster is configured to reject requests above a certain size (10MiB in this case). This corresponds to the `http.max_content_length` setting in `elasticsearch.yml`. Increase it to a larger size and restart your Elasticsearch cluster.

AWS has [fixed limits](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits) for this setting ("Maximum size of HTTP request payloads"), based on the size of the underlying instance.

## `Faraday::TimeoutError (execution expired)` error when using a proxy

Set a custom `gitlab_rails['env']` environment variable, called [`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables.html) with the IP address of your Elasticsearch host.

## My single node Elasticsearch cluster status never goes from `yellow` to `green` even though everything seems to be running properly

**For a single node Elasticsearch cluster the functional cluster health status is yellow** (never green) because the primary shard is allocated but replicas cannot be as there is no other node to which Elasticsearch can assign a replica. This also applies if you are using the [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) service.

WARNING:
Setting the number of replicas to `0` is discouraged (this is not allowed in the GitLab Elasticsearch Integration menu). If you are planning to add more Elasticsearch nodes (for a total of more than 1 Elasticsearch) the number of replicas needs to be set to an integer value larger than `0`. Failure to do so results in lack of redundancy (losing one node corrupts the index).

If you have a **hard requirement to have a green status for your single node Elasticsearch cluster**, please make sure you understand the risks outlined in the previous paragraph and then run the following query to set the number of replicas to `0`(the cluster no longer tries to create any shard replicas):

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## `health check timeout: no Elasticsearch node available` error in Sidekiq

If you're getting a `health check timeout: no Elasticsearch node available` error in Sidekiq during the indexing process:

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

You probably have not used either `http://` or `https://` as part of your value in the **"URL"** field of the Elasticsearch Integration Menu. Please make sure you are using either `http://` or `https://` in this field as the [Elasticsearch client for Go](https://github.com/olivere/elastic) that we are using [needs the prefix for the URL to be accepted as valid](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a).
After you have corrected the formatting of the URL, delete the index (via the [dedicated Rake task](elasticsearch.md#gitlab-advanced-search-rake-tasks)) and [reindex the content of your instance](elasticsearch.md#enable-advanced-search).

## My Elasticsearch cluster has a plugin and the integration is not working

Certain 3rd party plugins may introduce bugs in your cluster or for whatever
reason may be incompatible with our integration. You should try disabling
plugins so you can rule out the possibility that the plugin is causing the
problem.

## Elasticsearch `code_analyzer` doesn't account for all code cases

The `code_analyzer` pattern and filter configuration is being evaluated for improvement. We have fixed [most edge cases](https://gitlab.com/groups/gitlab-org/-/epics/3621#note_363429094) that were not returning expected search results due to our pattern and filter configuration.

Improvements to the `code_analyzer` pattern and filters are being discussed in [epic 3621](https://gitlab.com/groups/gitlab-org/-/epics/3621).

## Some binary files may not be searchable by name

In GitLab 13.9, a change was made where [binary file names are being indexed](https://gitlab.com/gitlab-org/gitlab/-/issues/301083). However, without indexing all projects' data from scratch, only binary files that are added or updated after the GitLab 13.9 release are searchable.

## How does Advanced Search handle private projects?

Advanced Search stores all the projects in the same Elasticsearch indices,
however, searches only surface results that can be viewed by the user.
Advanced Search honors all permission checks in the application by
filtering out projects that a user does not have access to at search time.

## Access requirements for the self-managed AWS OpenSearch Service

To use the self-managed AWS OpenSearch Service with GitLab, configure your instance's domain access policies
to contain the actions below.
See [Identity and Access Management in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html) for details.

```plaintext
es:ESHttpDelete
es:ESHttpGet
es:ESHttpHead
es:ESHttpPost
es:ESHttpPut
es:ESHttpPatch
```

## Role-mapping when using AWS Elasticsearch or AWS OpenSearch fine-grained access control

When using fine-grained access control with an IAM role, you might encounter the following error:

```plaintext
{"error":{"root_cause":[{"type":"security_exception","reason":"no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"}],"type":"security_exception","reason":"no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"},"status":403}
```

To fix this, you need to [map the roles to users](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping) in Kibana.
