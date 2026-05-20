## ADDED Requirements

### Requirement: YAML validation for safe-settings config

A Makefile target `safe-settings-validate` SHALL validate all YAML files
under `safe-settings/` using `yamllint`. The target SHALL use the same
`.yamllint.yml` configuration used for `peribolos.yaml`.

#### Scenario: YAML validation catches syntax error

- **GIVEN** a safe-settings YAML file has a syntax error (e.g., bad
  indentation)
- **WHEN** `make safe-settings-validate` is run
- **THEN** yamllint reports the error with file path and line number
- **AND** the command exits with a non-zero status

#### Scenario: YAML validation passes on correct config

- **GIVEN** all safe-settings YAML files have valid syntax
- **WHEN** `make safe-settings-validate` is run
- **THEN** yamllint reports no errors
- **AND** the command exits with status 0

### Requirement: Local dry-run for safe-settings

A Makefile target `safe-settings-dryrun` SHALL run safe-settings in dry-run
mode against the live GitHub org. This target SHALL:
- Depend on `ensure-safe-settings` (clone and install if not present)
- Use the Probot-native auth pattern (`APP_ID` + `PRIVATE_KEY` env vars)
- Read credentials from a local file (e.g.,
  `~/.config/safe-settings/env`) or expect them as environment variables
- Run `npm run full-sync` with `NODE_ENV=dry-run` or equivalent
- Display what changes would be applied without actually applying them

#### Scenario: Dry-run shows pending changes

- **GIVEN** the local safe-settings config differs from the live GitHub state
- **WHEN** `make safe-settings-dryrun` is run with valid credentials
- **THEN** the output shows what settings would be changed on which repos
- **AND** no actual changes are applied to the GitHub org

### Requirement: Ensure safe-settings binary/environment

A Makefile target `ensure-safe-settings` SHALL clone the safe-settings
repository and install its Node.js dependencies if not already present.
The target SHALL:
- Clone `github/safe-settings` at a pinned version/tag to a temporary or
  cached directory
- Run `npm install` in the cloned directory
- Be idempotent (skip clone and install if already present)
- Mirror the pattern used by `ensure-peribolos` for peribolos

#### Scenario: First run clones and installs

- **GIVEN** safe-settings has not been cloned locally
- **WHEN** `make ensure-safe-settings` is run
- **THEN** the safe-settings repo is cloned at the pinned version
- **AND** `npm install` completes successfully

#### Scenario: Subsequent runs are no-ops

- **GIVEN** safe-settings is already cloned and installed
- **WHEN** `make ensure-safe-settings` is run
- **THEN** the target prints a message indicating it is already present
- **AND** does not re-clone or re-install

### Requirement: Lint target covers safe-settings YAML

The existing `make lint` target SHALL be extended (or a new combined target
created) to validate both `peribolos.yaml` and `safe-settings/**/*.yml`
files. This ensures all org management YAML is linted consistently.

#### Scenario: Lint catches error in safe-settings file

- **GIVEN** a safe-settings YAML file has a lint violation
- **WHEN** `make lint` is run
- **THEN** yamllint reports the error
- **AND** the command exits with a non-zero status
