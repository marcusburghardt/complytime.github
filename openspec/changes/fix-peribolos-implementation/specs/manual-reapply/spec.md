## ADDED Requirements

**Depends on**: `token-auth` (authentication mechanism)

### Requirement: Workflow dispatch trigger for on-demand reapply
The apply workflow SHALL include a `workflow_dispatch` trigger so users with write access to the repository can manually reapply Peribolos settings at any time. Authorization relies on GitHub's built-in access control for `workflow_dispatch`.

#### Scenario: Admin triggers manual reapply
- **GIVEN** the apply workflow is deployed with `workflow_dispatch` trigger and the user has write access to the repository
- **WHEN** the user navigates to the workflow in GitHub Actions and clicks "Run workflow"
- **THEN** the workflow generates a fresh installation token (per `token-auth` spec), runs Peribolos with `--confirm`, and applies all settings from `peribolos.yaml`

### Requirement: Dry-run option for manual dispatch
The `workflow_dispatch` trigger SHALL accept a boolean input named `dry-run` (default: `false`). When `true`, Peribolos SHALL run without the `--confirm` flag, showing what would change without making mutations.

#### Scenario: Admin triggers dry-run
- **GIVEN** the apply workflow is deployed with the `dry-run` input
- **WHEN** a user triggers the workflow with `dry-run` set to `true`
- **THEN** Peribolos runs without `--confirm` and logs what changes would be made without applying them

#### Scenario: Admin triggers normal apply
- **GIVEN** the apply workflow is deployed with the `dry-run` input
- **WHEN** a user triggers the workflow with `dry-run` set to `false` (or default)
- **THEN** Peribolos runs with `--confirm` and applies all changes
