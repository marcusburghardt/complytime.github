## ADDED Requirements

### Requirement: No unrecognized keys in peribolos.yaml
The `peribolos.yaml` configuration SHALL NOT contain keys that are not recognized by the Peribolos org config schema. Unrecognized keys are silently ignored and indicate config errors.

#### Scenario: Orphan docs key is removed
- **GIVEN** `peribolos.yaml` currently contains a `docs:` key at the org level that is not a recognized Peribolos config field
- **WHEN** the config is corrected
- **THEN** the `docs:` key and its contents are removed from `peribolos.yaml`

### Requirement: Org admins listed as team maintainers not members
Org admins SHALL NOT appear in any team's `members:` list. Org admins who are part of a team MUST be listed under `maintainers:` instead, because GitHub automatically grants admin-level access to org owners and Peribolos validates this distinction.

#### Scenario: Org admin not in team members
- **GIVEN** `jpower432` and `marcusburghardt` are org admins (listed in `admins:`)
- **WHEN** `testTeamMembers()` checks team membership
- **THEN** neither admin appears in any team's `members:` list (they are in `maintainers:` instead)

### Requirement: testTeamMembers validation is active
The `testTeamMembers()` function in `config/config_test.go` SHALL be called from `TestOrgs()` for every org's teams. This function validates team privacy, prevents admins from being listed as regular members, checks for duplicates, and verifies sorted member lists.

#### Scenario: Dead test code is wired into test suite
- **GIVEN** `testTeamMembers()` exists in `config/config_test.go` but is currently not called
- **WHEN** `TestOrgs()` runs
- **THEN** `testTeamMembers()` is invoked for each org's teams and its validations are enforced

#### Scenario: Tests pass with corrected config
- **GIVEN** org admins have been moved from `members:` to `maintainers:` and the orphan `docs:` key has been removed
- **WHEN** `go test ./config/...` is executed
- **THEN** all tests pass including the newly-wired `testTeamMembers()` validations
