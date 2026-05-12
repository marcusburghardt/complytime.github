## ADDED Requirements

### Requirement: Rename openscap-plugin-approvers to openscap-provider-approvers

The peribolos configuration SHALL rename the team `openscap-plugin-approvers` to
`openscap-provider-approvers`. The team description SHALL reference
"openscap-provider in complytime-providers". Maintainers SHALL be `jpower432`
and `marcusburghardt`. Members SHALL be `gvauter`, `hbraswelrh`, `sonupreetam`,
and `trevor-vaughan`. The team SHALL have write access to `complytime-providers`
and SHALL NOT have access to `complyctl`.

#### Scenario: Team renamed and repo access updated

- **WHEN** peribolos applies the configuration
- **THEN** the team `openscap-plugin-approvers` is renamed to
  `openscap-provider-approvers` with write access to `complytime-providers`
  and no access to `complyctl`

### Requirement: Create ampel-provider-approvers team

The peribolos configuration SHALL define a team `ampel-provider-approvers` with
`privacy: closed`. Maintainers SHALL be `jpower432` and `marcusburghardt`.
Members SHALL be `gvauter`, `hbraswelrh`, `sonupreetam`, and `trevor-vaughan`.
The team SHALL have write access to `complytime-providers`.

#### Scenario: Team created with correct membership

- **WHEN** peribolos applies the configuration
- **THEN** the team `ampel-provider-approvers` exists with `privacy: closed`,
  the specified maintainers and members, and write access to
  `complytime-providers`

### Requirement: Create opa-provider-approvers team

The peribolos configuration SHALL define a team `opa-provider-approvers` with
`privacy: closed`. Maintainers SHALL be `jpower432` and `marcusburghardt`.
Members SHALL be `fortiz-ai`, `gvauter`, `hbraswelrh`, `sonupreetam`, and
`trevor-vaughan`. The team SHALL have write access to `complytime-providers`.

#### Scenario: Team created with provider-specific member

- **WHEN** peribolos applies the configuration
- **THEN** the team `opa-provider-approvers` exists with `fortiz-ai` as a
  member in addition to all complytime-dev members

### Requirement: Create complytime-policies-approvers team

The peribolos configuration SHALL define a team `complytime-policies-approvers`
with `privacy: closed`. Maintainers SHALL be `jflowers`, `jpower432`, and
`marcusburghardt`. Members SHALL include `fortiz-ai`. The team SHALL have write
access to `complytime-policies`.

#### Scenario: Team created for Gemara content ownership

- **WHEN** peribolos applies the configuration
- **THEN** the team `complytime-policies-approvers` exists with `privacy: closed`,
  the specified maintainers, `fortiz-ai` as a member, and write access to
  `complytime-policies`

### Requirement: Repurpose complytime-approvers team

The peribolos configuration SHALL update `complytime-approvers` with
description "Write access to non-code repos for project stakeholders".
Maintainers SHALL be `jflowers`, `jpower432`, and `marcusburghardt`. Members
SHALL be `beatrizmcouto` and `hbraswelrh`. The team SHALL have write access to
`.github`, `community`, `complytime-demos`, and `website`. The team SHALL NOT
have write access to `complyctl` or `complytime`.

#### Scenario: Team repurposed with updated membership and repos

- **WHEN** peribolos applies the configuration
- **THEN** the team `complytime-approvers` has the updated description,
  maintainers (jflowers, jpower432, marcusburghardt), members (beatrizmcouto,
  hbraswelrh), and write access only to `.github`, `community`,
  `complytime-demos`, and `website`

#### Scenario: Previous members removed

- **WHEN** peribolos applies the configuration
- **THEN** `gvauter`, `sonupreetam`, and `trevor-vaughan` are no longer
  members of `complytime-approvers`

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

- **WHEN** a team in peribolos.yaml uses `privacy: secret`
- **THEN** the config_test.go validation fails with an error indicating
  the team does not have the `privacy: closed` field

### Requirement: Team maintainers must be org admins

All team maintainers in peribolos.yaml SHALL be organization admins. Non-admin
users SHALL be listed as team members, not maintainers. Organization admins
listed in a team SHALL be listed as maintainers, not members.

#### Scenario: Non-admin listed as maintainer

- **WHEN** a non-admin user is listed as a team maintainer in peribolos.yaml
- **THEN** the config_test.go validation fails with an error indicating
  the user should be in the members list

#### Scenario: Admin listed as member

- **WHEN** an org admin is listed as a team member in peribolos.yaml
- **THEN** the config_test.go validation fails with an error indicating
  the user should be in the maintainers list

### Requirement: Team member and maintainer lists must be sorted

All maintainer and member lists in peribolos.yaml team definitions SHALL be
sorted alphabetically.

#### Scenario: Unsorted member list

- **WHEN** a team has an unsorted member list in peribolos.yaml
- **THEN** the config_test.go validation fails with an error indicating
  the list is unsorted
