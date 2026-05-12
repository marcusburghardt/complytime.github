## ADDED Requirements

### Requirement: Rename openscap-plugin-approvers to openscap-provider-approvers

The peribolos configuration SHALL rename the team `openscap-plugin-approvers` to
`openscap-provider-approvers`. The team SHALL have `privacy: closed`. The team
description SHALL reference "openscap-provider in complytime-providers".
Maintainers SHALL be `jpower432` and `marcusburghardt`. Members SHALL be
`gvauter`, `hbraswelrh`, `sonupreetam`, and `trevor-vaughan`. The team SHALL
have write access to `complytime-providers` and SHALL NOT have access to
`complyctl`.

#### Scenario: Team renamed and repo access updated

- **GIVEN** the peribolos.yaml file contains the updated team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** a team `openscap-provider-approvers` exists with `privacy: closed`,
  maintainers `["jpower432", "marcusburghardt"]`, members `["gvauter",
  "hbraswelrh", "sonupreetam", "trevor-vaughan"]`, and repos including
  `complytime-providers: write`
- **AND** no team named `openscap-plugin-approvers` exists

### Requirement: Create ampel-provider-approvers team

The peribolos configuration SHALL define a team `ampel-provider-approvers` with
`privacy: closed`. Maintainers SHALL be `jpower432` and `marcusburghardt`.
Members SHALL be `gvauter`, `hbraswelrh`, `sonupreetam`, and `trevor-vaughan`.
The team SHALL have write access to `complytime-providers`.

#### Scenario: Team created with correct membership

- **GIVEN** the peribolos.yaml file contains the team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** the team `ampel-provider-approvers` exists with `privacy: closed`,
  maintainers `["jpower432", "marcusburghardt"]`, members `["gvauter",
  "hbraswelrh", "sonupreetam", "trevor-vaughan"]`, and repos including
  `complytime-providers: write`

### Requirement: Create opa-provider-approvers team

The peribolos configuration SHALL define a team `opa-provider-approvers` with
`privacy: closed`. Maintainers SHALL be `jpower432` and `marcusburghardt`.
Members SHALL be `fortiz-ai`, `gvauter`, `hbraswelrh`, `sonupreetam`, and
`trevor-vaughan`. The team SHALL have write access to `complytime-providers`.

#### Scenario: Team created with provider-specific member

- **GIVEN** the peribolos.yaml file contains the team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** the team `opa-provider-approvers` exists with `privacy: closed`,
  members including `fortiz-ai` in addition to all complytime-dev members,
  and repos including `complytime-providers: write`

### Requirement: Create complytime-policies-approvers team

The peribolos configuration SHALL define a team `complytime-policies-approvers`
with `privacy: closed`. Maintainers SHALL be `jflowers`, `jpower432`, and
`marcusburghardt`. Members SHALL include `fortiz-ai`. The team SHALL have write
access to `complytime-policies`.

#### Scenario: Team created for Gemara content ownership

- **GIVEN** the peribolos.yaml file contains the team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** the team `complytime-policies-approvers` exists with `privacy: closed`,
  maintainers `["jflowers", "jpower432", "marcusburghardt"]`, member `fortiz-ai`,
  and repos including `complytime-policies: write`

### Requirement: Repurpose complytime-approvers team

The peribolos configuration SHALL update `complytime-approvers` with
description "Write access to non-code repos for project stakeholders".
Maintainers SHALL be `jflowers`, `jpower432`, and `marcusburghardt`. Members
SHALL be `beatrizmcouto` and `hbraswelrh`. The team SHALL have write access to
`.github`, `community`, `complytime-demos`, and `website`. The team SHALL NOT
have write access to `complyctl` or `complytime`.

#### Scenario: Team repurposed with updated membership and repos

- **GIVEN** the peribolos.yaml file contains the updated team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** the team `complytime-approvers` has maintainers `["jflowers",
  "jpower432", "marcusburghardt"]`, members `["beatrizmcouto", "hbraswelrh"]`,
  and repos `.github`, `community`, `complytime-demos`, `website` (all write)

#### Scenario: Previous members removed

- **GIVEN** the peribolos.yaml file contains the updated team definition
- **WHEN** peribolos.yaml is parsed
- **THEN** `gvauter`, `sonupreetam`, and `trevor-vaughan` are not listed as
  members of `complytime-approvers`

## PRESERVED Requirements

The following validations already exist in `config_test.go` (via
`testTeamMembers`). They are documented here to confirm they MUST be maintained
and will apply to all new and modified teams. No new test code is needed for
these — the existing validation covers them.

### Requirement: All teams use privacy closed

All teams in peribolos.yaml SHALL use `privacy: closed`. This is required
because CODEOWNERS team references require teams to be visible to all
organization members. In GitHub's team privacy model, `closed` means visible
to all organization members, while `secret` teams are only visible to team
members and organization owners and cannot be referenced in CODEOWNERS files.

References:
- CODEOWNERS visibility requirement:
  https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Team privacy values:
  https://docs.github.com/en/rest/teams/teams#create-a-team

#### Scenario: Secret team rejected by validation

- **GIVEN** peribolos.yaml is loaded and config_test.go runs `testTeamMembers`
- **WHEN** a team in peribolos.yaml uses `privacy: secret`
- **THEN** the validation fails with an error indicating the team does not have
  the `privacy: closed` field

### Requirement: Team maintainers must be org admins

All team maintainers in peribolos.yaml SHALL be organization admins. Non-admin
users SHALL be listed as team members, not maintainers. Organization admins
listed in a team SHALL be listed as maintainers, not members.

#### Scenario: Non-admin listed as maintainer

- **GIVEN** peribolos.yaml is loaded and config_test.go runs `testTeamMembers`
- **WHEN** a non-admin user is listed as a team maintainer
- **THEN** the validation fails with an error indicating the user should be in
  the members list

#### Scenario: Admin listed as member

- **GIVEN** peribolos.yaml is loaded and config_test.go runs `testTeamMembers`
- **WHEN** an org admin is listed as a team member
- **THEN** the validation fails with an error indicating the user should be in
  the maintainers list

### Requirement: Team member and maintainer lists must be sorted

All maintainer and member lists in peribolos.yaml team definitions SHALL be
sorted alphabetically.

#### Scenario: Unsorted member list

- **GIVEN** peribolos.yaml is loaded and config_test.go runs `testTeamMembers`
- **WHEN** a team has an unsorted member list
- **THEN** the validation fails with an error indicating the list is unsorted
