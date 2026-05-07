## Why

Peribolos has been silently failing on every run since April 16, 2026. The GitHub App user access token expired and the workflow's pipeline exit code masking (piping through `jq`) hides the failure, making every run appear successful. As a result, team-repo permissions, org membership changes, and other org settings declared in `peribolos.yaml` are never applied. Org maintainers resort to manual changes, undermining the entire org-as-code approach.

## What Changes

- **Fix authentication**: Replace the expired static `APP_ACCESS_TOKEN` with per-run installation tokens generated via `actions/create-github-app-token@v3`, using the existing `complytime-bot` GitHub App. This eliminates token expiry as a failure mode entirely.
- **Fix silent failure masking**: Add `set -o pipefail` to the apply step so Peribolos failures propagate as workflow failures instead of being swallowed by the `jq` pipeline.
- **Add manual reapply trigger**: Add `workflow_dispatch` to `apply_peribolos.yml` so org admins can reapply settings on demand.
- **Add daily scheduled reconciliation**: Add a cron schedule to run Peribolos daily, preventing drift accumulation between config changes.
- **Fix dead test code**: Wire the existing `testTeamMembers()` function into `TestOrgs()` in `config/config_test.go` — it is defined but never called, so team config validation never runs.
- **Fix org admins listed as team members**: Move `jpower432` and `marcusburghardt` from `members:` to `maintainers:` in teams where they appear (they are org admins and GitHub treats them differently).
- **Remove orphan config key**: Remove the unrecognized `docs:` key from `peribolos.yaml`.
- **Add weekly drift detection workflow**: Create a weekly scheduled workflow that detects org state drift and opens an issue when config and reality diverge. Weekly frequency is chosen because daily reconciliation handles remediation; this workflow is advisory.

## Capabilities

### New Capabilities

- `token-auth`: Replace static token authentication with per-run GitHub App installation token generation via `actions/create-github-app-token@v3`
- `manual-reapply`: Add `workflow_dispatch` trigger with optional dry-run input so org admins can reapply Peribolos on demand
- `scheduled-reconciliation`: Add daily cron schedule to the apply workflow for continuous reconciliation
- `drift-detection`: New weekly scheduled workflow that compares actual org state against `peribolos.yaml` and opens an issue on drift
- `config-hygiene`: Fix peribolos.yaml config errors and activate dead test code in `config/config_test.go`

### Modified Capabilities

<!-- No existing specs to modify -->

### Removed Capabilities

- `ghproxy-sidecar`: Remove the unused ghproxy background process from the apply workflow (Peribolos was never configured to route through it)
- `app-access-token`: Replace static `APP_ACCESS_TOKEN` secret with per-run installation tokens (old secret can be removed after migration)

## Impact

- **Workflows**: `apply_peribolos.yml` (authentication, triggers, error handling), new `drift_detection.yml`
- **Config**: `peribolos.yaml` (fix `docs:` key, fix admin/member placement in teams)
- **Tests**: `config/config_test.go` (activate dead test code)
- **Secrets**: New `COMPLYTIME_BOT_CLIENT_ID` and `COMPLYTIME_BOT_PRIVATE_KEY` secrets replace old `APP_ACCESS_TOKEN` (manual setup, already done)
- **Dependencies**: New workflow dependency on `actions/create-github-app-token@v3` (SHA-pinned per existing workflow conventions)
