---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Tuning Geo **(PREMIUM SELF)**

You can limit the number of concurrent operations the sites can run
in the background.

## Changing the sync/verification concurrency values

On the **primary** site:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Geo > Sites**.
1. Select **Edit** of the secondary site you want to tune.
1. Under **Tuning settings**, there are several variables that can be tuned to
   improve the performance of Geo:

   - Repository synchronization concurrency limit
   - File synchronization concurrency limit
   - Container repositories synchronization concurrency limit
   - Verification concurrency limit

Increasing the concurrency values increases the number of jobs that are scheduled.
However, this may not lead to more downloads in parallel unless the number of
available Sidekiq threads is also increased. For example, if repository synchronization
concurrency is increased from 25 to 50, you may also want to increase the number
of Sidekiq threads from 25 to 50. See the
[Sidekiq concurrency documentation](../../sidekiq/extra_sidekiq_processes.md#number-of-threads)
for more details.

## Repository re-verification

See
[Automatic background verification](../disaster_recovery/background_verification.md).
