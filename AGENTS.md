# Repository instructions

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues; external pull requests are not a triage
surface. See `docs/agents/issue-tracker.md`.

#### Issue lifecycle

When implementing a GitHub issue:

1. Read the issue and its comments before changing code.
2. Comment when blocked or when scope materially changes.
3. Before moving to another issue:
   - post a completion summary,
   - include the implementing commit and validation performed,
   - update its triage label (or remove the readiness label when closing), and
   - close it when its acceptance criteria are satisfied.
4. Work is not complete until the issue state matches the repository state.
5. At session close, compare issue-referencing commits with open issues and
   resolve any mismatch.

Use this completion gate for every ticket:

`tests pass -> review complete -> commit created -> issue commented -> label updated -> issue closed or handoff posted`

### Triage labels

The repository uses the five default triage labels. See
`docs/agents/triage-labels.md`.

### Domain docs

The repository uses a single-context domain layout. See
`docs/agents/domain.md`.
