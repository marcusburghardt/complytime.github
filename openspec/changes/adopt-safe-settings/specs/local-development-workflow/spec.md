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

### Requirement: Lint target covers safe-settings YAML

The existing `make lint` target SHALL be extended to validate both
`peribolos.yaml` and `safe-settings/**/*.yml` files. This ensures all
org management YAML is linted consistently.

#### Scenario: Lint catches error in safe-settings file

- **GIVEN** a safe-settings YAML file has a lint violation
- **WHEN** `make lint` is run
- **THEN** yamllint reports the error
- **AND** the command exits with a non-zero status

### Requirement: Boundary tests validate config locally

The Go tests in `config/boundary_test.go` SHALL be runnable locally
via `make test-unit` without any credentials or network access. These
tests parse the local YAML files and validate cross-tool consistency.

#### Scenario: Local boundary validation

- **GIVEN** a developer modifies safe-settings config
- **WHEN** they run `make test-unit`
- **THEN** boundary tests validate the config against peribolos.yaml
- **AND** report any violations (field overlap, missing repos, duplicates)
- **AND** no GitHub API calls or credentials are required

### Requirement: Full local validation via make sanity

The `make sanity` target SHALL include safe-settings YAML validation
as part of its checks (via the extended `make lint` target). Running
`make sanity` SHALL validate both peribolos and safe-settings configs.

#### Scenario: Sanity check covers safe-settings

- **GIVEN** a developer wants to verify all configs before committing
- **WHEN** they run `make sanity`
- **THEN** peribolos.yaml and safe-settings YAML are validated
- **AND** boundary tests are run
- **AND** the command exits with zero status if everything is correct
