## ADDED Requirements

**Depends on**: `token-auth` (for `peribolos --dump` authentication pattern)

### Requirement: Scheduled drift detection workflow
A new workflow SHALL run on a weekly schedule (e.g., `cron: '30 5 * * 1'` — Monday before the daily reconciliation), dump the current org state using `peribolos --dump`, and compare it against `peribolos.yaml`. When differences are detected, it SHALL open a GitHub issue. The workflow SHALL declare explicit `permissions:` with `contents: read` and `issues: write`.

#### Scenario: No drift detected
- **GIVEN** the `complytime-bot` app is installed and the org state matches `peribolos.yaml`
- **WHEN** the drift detection workflow runs
- **THEN** no issue is created and the workflow succeeds

#### Scenario: Drift detected
- **GIVEN** the org state differs from `peribolos.yaml` (e.g., a team-repo permission was changed via the GitHub UI)
- **WHEN** the drift detection workflow runs
- **THEN** a new GitHub issue is opened with the label `peribolos-drift`, a title like `Peribolos Drift Detected - <date>`, and a body containing the diff output wrapped in a fenced code block

#### Scenario: Existing open drift issue
- **GIVEN** an open issue with the `peribolos-drift` label already exists
- **WHEN** the drift detection workflow detects new drift
- **THEN** the workflow updates the existing issue body with the new diff instead of creating a duplicate

### Requirement: Drift detection uses separate authentication scopes
Issue creation/update SHALL use the workflow's default `GITHUB_TOKEN` with `issues: write` permission. The GitHub App installation token SHALL only be used for `peribolos --dump` (org read operations).

#### Scenario: Token scoping is correct
- **GIVEN** the drift detection workflow generates an installation token for `peribolos --dump`
- **WHEN** an issue needs to be created or updated
- **THEN** the `GITHUB_TOKEN` is used for issue operations, not the installation token

### Requirement: Diff output is sanitized for safe display
The diff output included in the issue body SHALL be wrapped in a fenced code block (triple backticks) to prevent Markdown injection (e.g., `@mentions`, `#references`). The diff SHALL be passed to the issue creation API via a file or environment variable, not inline shell expansion.

#### Scenario: Diff content is safely rendered
- **GIVEN** the org state contains usernames or metadata with special characters
- **WHEN** the diff is included in the GitHub issue body
- **THEN** the content is rendered as a code block without triggering notifications or rendering as active Markdown
