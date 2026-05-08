## ADDED Requirements

**Depends on**: `token-auth` (authentication mechanism)

### Requirement: Daily scheduled Peribolos execution
The apply workflow SHALL include a `schedule` trigger with a daily cron expression (e.g., `cron: '30 5 * * *'`) to automatically reconcile org state with `peribolos.yaml`. The cron time SHOULD avoid top-of-hour slots to reduce GitHub Actions scheduling delays.

#### Scenario: Daily cron triggers apply
- **GIVEN** the apply workflow is deployed with a daily `schedule` trigger
- **WHEN** the daily cron schedule fires
- **THEN** the workflow generates a fresh installation token (per `token-auth` spec), runs Peribolos with `--confirm`, and applies all settings from `peribolos.yaml`

#### Scenario: Scheduled run uses same authentication as push-triggered runs
- **GIVEN** the `token-auth` spec's installation token mechanism is deployed
- **WHEN** the daily cron triggers the workflow
- **THEN** the workflow generates a fresh installation token and authenticates identically to a push-triggered run

#### Scenario: Concurrent workflow runs prevented
- **GIVEN** the apply workflow uses a `concurrency` group
- **WHEN** a push-triggered and cron-triggered run overlap
- **THEN** the later run waits or cancels to prevent simultaneous Peribolos execution

#### Scenario: Schedule trigger on fork is skipped
- **GIVEN** the workflow is triggered by a cron schedule on a forked repository
- **WHEN** the repository owner is not `complytime`
- **THEN** the apply step is skipped (guarded by repository owner check)
