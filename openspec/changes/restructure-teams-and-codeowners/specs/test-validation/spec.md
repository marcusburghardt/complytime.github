## ADDED Requirements

### Requirement: CODEOWNERS path updated for .github location

The config_test.go `--owners-dir` flag default SHALL be updated from `"../"`
to `"../.github"` to reflect the new standardized CODEOWNERS location at
`.github/CODEOWNERS`. The `loadOwners` function SHALL read CODEOWNERS from
the `.github/` directory.

#### Scenario: Test reads CODEOWNERS from .github directory

- **WHEN** config_test.go runs with default flags
- **THEN** the test reads the CODEOWNERS file from `../.github/CODEOWNERS`
  instead of `../CODEOWNERS`

### Requirement: CODEOWNERS parsing separates users from teams

The `loadOwners` function SHALL separate CODEOWNERS entries into individual
users and team references. A team reference is identified by the presence of
a `/` character in the owner string (e.g., `@complytime/complytime-approvers`).
Individual users do not contain a `/`.

#### Scenario: Mixed individual and team owners parsed

- **WHEN** the CODEOWNERS file contains
  `* @jflowers @jpower432 @marcusburghardt @complytime/complytime-approvers`
- **THEN** individual users are `["jflowers", "jpower432", "marcusburghardt"]`
  and team references are `["complytime/complytime-approvers"]`

### Requirement: Individual CODEOWNERS users validated as org admins

The test SHALL validate that all individual users listed in CODEOWNERS are
org admins. This preserves the existing validation behavior. The minimum of
3 individual approvers requirement SHALL be maintained.

#### Scenario: Non-admin individual in CODEOWNERS

- **WHEN** the CODEOWNERS file lists an individual user who is not an org admin
- **THEN** the test fails with an error indicating the user does not match
  org admins

#### Scenario: Fewer than 3 individual approvers

- **WHEN** the CODEOWNERS file lists fewer than 3 individual users
- **THEN** the test fails with an error indicating insufficient approvers

### Requirement: Team references validated against peribolos config

The test SHALL validate that all team references in CODEOWNERS correspond to
teams defined in peribolos.yaml. The team name extracted from the CODEOWNERS
entry (the part after the `/`, e.g., `complytime-approvers` from
`@complytime/complytime-approvers`) MUST exist as a key in the org's teams map.

#### Scenario: Valid team reference

- **WHEN** the CODEOWNERS file references `@complytime/complytime-approvers`
  and the team `complytime-approvers` exists in peribolos.yaml
- **THEN** the test passes the team reference validation

#### Scenario: Invalid team reference

- **WHEN** the CODEOWNERS file references `@complytime/nonexistent-team`
  and no team `nonexistent-team` exists in peribolos.yaml
- **THEN** the test fails with an error indicating the team does not exist
  in the org configuration

### Requirement: No duplicate owners in CODEOWNERS

The test SHALL validate that there are no duplicate entries in the CODEOWNERS
file, checking both individual users and team references.

#### Scenario: Duplicate individual user

- **WHEN** the CODEOWNERS file lists the same user twice
- **THEN** the test fails with a duplicate approvers error

#### Scenario: Duplicate team reference

- **WHEN** the CODEOWNERS file lists the same team twice
- **THEN** the test fails with a duplicate teams error
