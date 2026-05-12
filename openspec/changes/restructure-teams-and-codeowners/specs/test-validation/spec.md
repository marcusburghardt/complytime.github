## ADDED Requirements

### Requirement: CODEOWNERS path updated for .github location

The config_test.go `--owners-dir` flag default SHALL be updated from `"../"`
to `"../.github"` to reflect the new standardized CODEOWNERS location at
`.github/CODEOWNERS`. The `loadOwners` function SHALL read CODEOWNERS from
the `.github/` directory.

#### Scenario: Test reads CODEOWNERS from .github directory

- **GIVEN** config_test.go runs with default flags
- **WHEN** `loadOwners` is invoked
- **THEN** the test reads the CODEOWNERS file from `../.github/CODEOWNERS`
  instead of `../CODEOWNERS`

### Requirement: CODEOWNERS parsing separates users from teams

The `loadOwners` function SHALL return separate lists for individual users
and team references. The return signature SHALL be
`(users []string, teams []string, err error)`.

A team reference is identified by the presence of a `/` character in the owner
string (e.g., `@complytime/complytime-approvers`). Individual users do not
contain a `/`.

Individual users SHALL have the `@` prefix stripped (e.g., `"jflowers"` not
`"@jflowers"`). Team references SHALL retain the org-qualified form without
`@` (e.g., `"complytime/complytime-approvers"`).

#### Scenario: Mixed individual and team owners parsed

- **GIVEN** the CODEOWNERS file contains
  `* @jflowers @jpower432 @marcusburghardt @complytime/complytime-approvers`
- **WHEN** `loadOwners` parses the file
- **THEN** individual users are `["jflowers", "jpower432", "marcusburghardt"]`
  and team references are `["complytime/complytime-approvers"]`

### Requirement: Individual CODEOWNERS users validated as org admins

The test SHALL validate that all individual users listed in CODEOWNERS are
org admins. This preserves the existing validation behavior. The minimum of
3 individual approvers requirement SHALL be maintained.

#### Scenario: Non-admin individual in CODEOWNERS

- **GIVEN** peribolos.yaml is loaded with its org admin list
- **WHEN** the CODEOWNERS file lists an individual user who is not an org admin
- **THEN** the test fails with an error indicating the user does not match
  org admins

#### Scenario: Fewer than 3 individual approvers

- **GIVEN** peribolos.yaml is loaded
- **WHEN** the CODEOWNERS file lists fewer than 3 individual users
- **THEN** the test fails with an error indicating insufficient approvers

### Requirement: Team references validated against peribolos config

The test SHALL validate that all team references in CODEOWNERS correspond to
teams defined in peribolos.yaml. The team name extracted from the CODEOWNERS
entry (the part after the `/`, e.g., `complytime-approvers` from
`complytime/complytime-approvers`) MUST exist as a key in the org's teams map.

#### Scenario: Valid team reference

- **GIVEN** peribolos.yaml is loaded and contains the team `complytime-approvers`
- **WHEN** the CODEOWNERS file references `@complytime/complytime-approvers`
- **THEN** the test passes the team reference validation

#### Scenario: Invalid team reference

- **GIVEN** peribolos.yaml is loaded and contains no team `nonexistent-team`
- **WHEN** the CODEOWNERS file references `@complytime/nonexistent-team`
- **THEN** the test fails with an error indicating the team does not exist
  in the org configuration

### Requirement: No duplicate owners in CODEOWNERS

The test SHALL validate that there are no duplicate entries in the CODEOWNERS
file, checking both individual users and team references independently.

#### Scenario: Duplicate individual user

- **GIVEN** the CODEOWNERS file has been parsed
- **WHEN** the same user appears twice in the owners list
- **THEN** the test fails with a duplicate approvers error

#### Scenario: Duplicate team reference

- **GIVEN** the CODEOWNERS file has been parsed
- **WHEN** the same team appears twice in the owners list
- **THEN** the test fails with a duplicate teams error

## PRESERVED Requirements

The following validations already exist in `config_test.go` and MUST be
maintained. The `loadOwners` changes MUST NOT regress these behaviors:

- **Privacy check**: `testTeamMembers` validates all teams have `privacy: closed`
- **Admin-as-maintainer check**: `testTeamMembers` validates non-admins are not
  listed as maintainers and admins are not listed as regular members
- **Sorted lists check**: `testTeamMembers` validates maintainer and member lists
  are alphabetically sorted
- **Org membership check**: `testTeamMembers` validates all team members are org
  members
- **Duplicate check**: `testTeamMembers` validates no duplicate maintainers or
  members within a team
