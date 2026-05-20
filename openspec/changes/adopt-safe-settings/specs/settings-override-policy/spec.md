## ADDED Requirements

### Requirement: Override validators defined in deployment settings

The `deployment-settings.yml` SHALL define `overridevalidators` that prevent
suborg or repo level settings from weakening org-level protections.

#### Scenario: Override validator prevents weakening required approvers

- **GIVEN** the org-level settings define
  `required_approving_review_count: 1`
- **AND** an `overridevalidator` for `branches` checks that the override count
  is not lower than the base count
- **WHEN** a repo-level config sets `required_approving_review_count: 0`
- **THEN** safe-settings rejects the override and reports a validation error
  in the sync workflow logs

### Requirement: Config validators for collaborator permissions

The `deployment-settings.yml` SHALL define `configvalidators` that prevent
granting `admin` permission to collaborators at any config level.

#### Scenario: Admin permission for collaborator rejected

- **GIVEN** a `configvalidator` for `collaborators` checks that permission
  is not `admin`
- **WHEN** a config file grants a collaborator `admin` permission
- **THEN** safe-settings rejects the config and reports a validation error

### Requirement: Validators produce clear error messages

All validators (both `configvalidators` and `overridevalidators`) SHALL include
an `error` field with a human-readable message explaining why the validation
failed and what the correct configuration should be.

#### Scenario: Validation error message in sync output

- **GIVEN** a config contains an invalid override
- **WHEN** safe-settings runs the full sync
- **THEN** the sync output includes the validator's error message
- **AND** the error message explains which policy was violated

### Requirement: Validators enforced during full sync

Validators SHALL run during every full sync (push-triggered, scheduled, or
manual dispatch). If a validator fails during sync, the affected settings
change SHALL NOT be applied and an error SHALL be reported in the workflow
logs.

#### Scenario: Validator blocks apply on push to main

- **GIVEN** a config change that violates an override validator was merged
  (e.g., the validator was added after the config was already committed)
- **WHEN** safe-settings runs the full sync
- **THEN** the invalid settings are not applied
- **AND** the workflow logs report the validation error
