---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Style guides

## Editor/IDE styling standardization

We use [EditorConfig](https://editorconfig.org/) to automatically apply certain styling
standards before files are saved locally. Most editors/IDEs will honor the `.editorconfig`
settings automatically by default. If your editor/IDE does not automatically support `.editorconfig`,
we suggest investigating to see if a plugin exists. For instance here is the
[plugin for vim](https://github.com/editorconfig/editorconfig-vim).

## Pre-push static analysis with Lefthook

[Lefthook](https://github.com/Arkweid/lefthook) is a Git hooks manager that allows
custom logic to be executed prior to Git committing or pushing. GitLab comes with
Lefthook configuration (`lefthook.yml`), but it must be installed.

We have a `lefthook.yml` checked in but it is ignored until Lefthook is installed.

### Uninstall Overcommit

We were using Overcommit prior to Lefthook, so you may want to uninstall it first with `overcommit --uninstall`.

### Install Lefthook

1. Install the `lefthook` Ruby gem:

   ```shell
   bundle install
   ```

1. Install Lefthook managed Git hooks:

   ```shell
   bundle exec lefthook install
   ```

1. Test Lefthook is working by running the Lefthook `prepare-commit-msg` Git hook:

   ```shell
   bundle exec lefthook run prepare-commit-msg
   ```

This should return a fully qualified path command with no other output.

### Lefthook configuration

Lefthook is configured with a combination of:

- Project configuration in [`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml).
- Any [local configuration](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#local-config).

### Disable Lefthook temporarily

To disable Lefthook temporarily, you can set the `LEFTHOOK` environment variable to `0`. For instance:

```shell
LEFTHOOK=0 git push ...
```

### Run Lefthook hooks manually

To run the `pre-push` Git hook, run:

```shell
bundle exec lefthook run pre-push
```

For more information, check out [Lefthook documentation](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#run-githook-group-directly).

### Skip Lefthook checks per tag

To skip some checks based on tags when pushing, you can set the `LEFTHOOK_EXCLUDE` environment variable. For instance:

```shell
LEFTHOOK_EXCLUDE=frontend,documentation git push ...
```

As an alternative, you can create `lefthook-local.yml` with this structure:

```yaml
pre-push:
  exclude_tags:
    - frontend
    - documentation
```

For more information, check out [Lefthook documentation](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#skip-some-tags-on-the-fly).

### Skip or enable a specific Lefthook check

To skip or enable a check based on its name when pushing, you can add `skip: true`
or `skip: false` to the `lefthook-local.yml` section for that hook. For instance,
you might want to enable the gettext check to detect issues with `locale/gitlab.pot`:

```yaml
pre-push:
  commands:
    gettext:
      skip: false
```

For more information, check out [Lefthook documentation Skipping commands section](https://github.com/evilmartians/lefthook/blob/master/docs/full_guide.md#skipping-commands).

## Ruby, Rails, RSpec

Our codebase style is defined and enforced by [RuboCop](https://github.com/rubocop-hq/rubocop).

You can check for any offenses locally with `bundle exec rubocop --parallel`.
On the CI, this is automatically checked by the `static-analysis` jobs.

In addition, you can [integrate RuboCop](../developing_with_solargraph.md) into
supported IDEs using the [Solargraph](https://github.com/castwide/solargraph) gem.

For RuboCop rules that we have not taken a decision on yet, we follow the
[Ruby Style Guide](https://github.com/rubocop-hq/ruby-style-guide),
[Rails Style Guide](https://github.com/rubocop-hq/rails-style-guide), and
[RSpec Style Guide](https://github.com/rubocop-hq/rspec-style-guide) as general
guidelines to write idiomatic Ruby/Rails/RSpec, but reviewers/maintainers should
be tolerant and not too pedantic about style.

Similarly, some RuboCop rules are currently disabled, and for those,
reviewers/maintainers must not ask authors to use one style or the other, as both
are accepted. This isn't an ideal situation since this leaves space for
[bike-shedding](https://en.wiktionary.org/wiki/bikeshedding), and ideally we
should enable all RuboCop rules to avoid style-related
discussions/nitpicking/back-and-forth in reviews. There are some styles that
commonly come up in reviews that are not enforced, the
[GitLab Ruby style guide](../backend/ruby_style_guide.md) includes a non-exhaustive
list of these topics.

Additionally, we have a dedicated
[newlines style guide](../newlines_styleguide.md), as well as dedicated
[test-specific style guides and best practices](../testing_guide/index.md).

### Creating new RuboCop cops

Typically it is better for the linting rules to be enforced programmatically as it
reduces the aforementioned [bike-shedding](https://en.wiktionary.org/wiki/bikeshedding).

To that end, we encourage creation of new RuboCop rules in the codebase.

We maintain Cops across several Ruby code bases, and not all of them are
specific to the GitLab application.
When creating a new cop that could be applied to multiple applications, we encourage you
to add it to our [GitLab Styles](https://gitlab.com/gitlab-org/gitlab-styles) gem.
If the Cop targets rules that only apply to the main GitLab application,
it should be added to [GitLab](https://gitlab.com/gitlab-org/gitlab) instead.

#### RuboCop node pattern

When creating [node patterns](https://docs.rubocop.org/rubocop-ast/node_pattern.html) to match
Ruby's AST, you can use [`scripts/rubocop-parse`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/rubocop-parse)
to display the AST of a Ruby expression, in order to help you create the matcher.
See also [!97024](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97024).

### Resolving RuboCop exceptions

When the number of RuboCop exceptions exceed the default [`exclude-limit` of 15](https://docs.rubocop.org/rubocop/1.2/usage/basic_usage.html#command-line-flags),
we may want to resolve exceptions over multiple commits. To minimize confusion,
we should track our progress through the exception list.

The preferred way to [generate the initial list or a list for specific RuboCop rules](../rake_tasks.md#generate-initial-rubocop-todo-list)
is to run the Rake task `rubocop:todo:generate`:

```shell
# Initial list
bundle exec rake rubocop:todo:generate

# List for specific RuboCop rules
bundle exec rake 'rubocop:todo:generate[Gitlab/NamespacedClass,Lint/Syntax]'
```

This Rake task creates or updates the exception list in `.rubocop_todo/`. For
example, the configuration for the RuboCop rule `Gitlab/NamespacedClass` is
located in `.rubocop_todo/gitlab/namespaced_class.yml`.

Make sure to commit any changes in `.rubocop_todo/` after running the Rake task.

### Reveal existing RuboCop exceptions

To reveal existing RuboCop exceptions in the code that have been excluded via `.rubocop_todo.yml` and
`.rubocop_todo/**/*.yml`, set the environment variable `REVEAL_RUBOCOP_TODO` to `1`.

This allows you to reveal existing RuboCop exceptions during your daily work cycle and fix them along the way.

NOTE:
Define permanent `Exclude`s in `.rubocop.yml` instead of `.rubocop_todo/**/*.yml`.

## Database migrations

See the dedicated [Database Migrations Style Guide](../migration_style_guide.md).

## JavaScript

See the dedicated [JS Style Guide](../fe_guide/style/javascript.md).

## SCSS

See the dedicated [SCSS Style Guide](../fe_guide/style/scss.md).

## Go

See the dedicated [Go standards and style guidelines](../go_guide/index.md).

## Shell commands (Ruby)

See the dedicated [Guidelines for shell commands in the GitLab codebase](../shell_commands.md).

## Shell scripting

See the dedicated [Shell scripting standards and style guidelines](../shell_scripting_guide/index.md).

## Markdown

<!-- vale gitlab.Spelling = NO -->

We're following [Ciro Santilli's Markdown Style Guide](https://cirosantilli.com/markdown-style-guide/).

<!-- vale gitlab.Spelling = YES -->

## Documentation

See the dedicated [Documentation Style Guide](../documentation/styleguide/index.md).

### Guidelines for good practices

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36576/) in GitLab 13.2 as GitLab Development documentation.

*Good practice* examples demonstrate encouraged ways of writing code while
comparing with examples of practices to avoid. These examples are labeled as
*Bad* or *Good*. In GitLab development guidelines, when presenting the cases,
it's recommended to follow a *first-bad-then-good* strategy. First demonstrate
the *Bad* practice (how things *could* be done, which is often still working
code), and then how things *should* be done better, using a *Good* example. This
is typically an improved example of the same code.

Consider the following guidelines when offering examples:

- First, offer the *Bad* example, and then the *Good* one.
- When only one bad case and one good case is given, use the same code block.
- When more than one bad case or one good case is offered, use separated code
  blocks for each. With many examples being presented, a clear separation helps
  the reader to go directly to the good part. Consider offering an explanation
  (for example, a comment, or a link to a resource) on why something is bad
  practice.
- Better and best cases can be considered part of the good cases' code block.
  In the same code block, precede each with comments: `# Better` and `# Best`.

Although the bad-then-good approach is acceptable for the GitLab development
guidelines, do not use it for user documentation. For user documentation, use
*Do* and *Don't*. For examples, see the [Pajamas Design System](https://design.gitlab.com/content/punctuation/).

## Python

See the dedicated [Python Development Guidelines](../python_guide/index.md).

## Misc

Code should be written in [US English](https://en.wikipedia.org/wiki/American_English).
