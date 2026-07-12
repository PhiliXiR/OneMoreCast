# Issue tracker: GitHub

Issues and specifications for this repo live as GitHub issues. Use the `gh` CLI
for all operations and infer the repository from `git remote -v`.

## Conventions

- Create issues with `gh issue create`.
- Read issues and comments with `gh issue view <number> --comments`.
- List issues with `gh issue list`, requesting JSON when output will be consumed
  by an agent.
- Comment with `gh issue comment`.
- Apply or remove labels with `gh issue edit`.
- Close issues with `gh issue close`.

## Pull requests as a triage surface

External pull requests are not a request or triage surface. Issues are the
planning and request surface; pull requests represent implementation already in
progress.

## Skill operations

When a skill says to publish to the issue tracker, create a GitHub issue. When a
skill says to fetch a ticket, read the corresponding GitHub issue and its
comments.
