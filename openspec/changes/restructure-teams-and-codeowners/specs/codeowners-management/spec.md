## ADDED Requirements

### Requirement: CODEOWNERS standardized to .github directory

All CODEOWNERS files across the complytime organization SHALL be located at
`.github/CODEOWNERS` within each repository. This follows GitHub's recommended
location and search priority order (`.github/`, root, `docs/`).

Reference:
https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

#### Scenario: This repo CODEOWNERS moved from root to .github

- **GIVEN** the `.github` repository previously had CODEOWNERS at the root
- **WHEN** the migration is complete
- **THEN** `.github/CODEOWNERS` exists with the ownership rules
- **AND** the root `CODEOWNERS` file is deleted

### Requirement: .github repo CODEOWNERS lists only org admins

The `.github` repository CODEOWNERS SHALL list only individual org admin
users as code owners. The `@complytime/complytime-approvers` team SHALL NOT
be included in CODEOWNERS, despite having write access to the repository.
The file at `.github/CODEOWNERS` SHALL contain the line:

```
* @jflowers @jpower432 @marcusburghardt
```

This separation between write access (via team) and approval authority (via
CODEOWNERS) prevents privilege escalation. With `require_code_owner_review:
true` in the repository ruleset, only org admins can approve merges to
peribolos.yaml and other org management files.

#### Scenario: CODEOWNERS file content validated

- **GIVEN** the `.github/CODEOWNERS` file exists in this repository
- **WHEN** the file is read
- **THEN** it contains the line `* @jflowers @jpower432 @marcusburghardt`
- **AND** no team references appear in the file

### Requirement: complyctl CODEOWNERS cleaned up

The complyctl repository (at `.github/CODEOWNERS`, which is the file's current
location) SHALL be simplified to a single fallback rule assigning
`@complytime/complytime-dev` as the owner for all files. The stale
`/cmd/openscap-plugin/` rule and the `/cmd/complyctl/` specific rule SHALL be
removed.

#### Scenario: Stale openscap-plugin rule removed

- **GIVEN** the complyctl `.github/CODEOWNERS` file has been updated
- **WHEN** the file is read
- **THEN** there is no rule referencing `/cmd/openscap-plugin/` or
  `@complytime/openscap-plugin-approvers`

#### Scenario: Single fallback rule

- **GIVEN** the complyctl `.github/CODEOWNERS` file has been updated
- **WHEN** the file is read
- **THEN** the only rule is `* @complytime/complytime-dev`

Note: GitHub will request review from `@complytime/complytime-dev` for all PRs.

### Requirement: complytime-providers CODEOWNERS created with per-provider rules

The complytime-providers repository SHALL have a CODEOWNERS file at
`.github/CODEOWNERS` with a fallback rule for `@complytime/complytime-dev`
and per-provider path rules for each provider directory under `cmd/`.

The file SHALL contain:
```
* @complytime/complytime-dev
/cmd/openscap-provider/ @complytime/openscap-provider-approvers
/cmd/ampel-provider/ @complytime/ampel-provider-approvers
/cmd/opa-provider/ @complytime/opa-provider-approvers
```

#### Scenario: CODEOWNERS file content validated

- **GIVEN** the complytime-providers `.github/CODEOWNERS` file has been created
- **WHEN** the file is read
- **THEN** it contains the fallback rule `* @complytime/complytime-dev` and
  per-provider rules for `/cmd/openscap-provider/`, `/cmd/ampel-provider/`,
  and `/cmd/opa-provider/`

Note: GitHub uses last-matching-pattern semantics. A PR modifying only
`/cmd/openscap-provider/` triggers review from `openscap-provider-approvers`
only. A PR modifying both `/cmd/openscap-provider/` and `/internal/` triggers
review from both the provider team and `complytime-dev`. Shared code under
`/internal/` or root-level files match only the `*` fallback.

### Requirement: complytime-policies CODEOWNERS created

The complytime-policies repository SHALL have a CODEOWNERS file at
`.github/CODEOWNERS` with a single fallback rule assigning both
`@complytime/complytime-policies-approvers` and `@complytime/complytime-dev`
as code owners for all files.

```
* @complytime/complytime-policies-approvers @complytime/complytime-dev
```

#### Scenario: CODEOWNERS file content validated

- **GIVEN** the complytime-policies `.github/CODEOWNERS` file has been created
- **WHEN** the file is read
- **THEN** it contains the line
  `* @complytime/complytime-policies-approvers @complytime/complytime-dev`

Note: GitHub will request review from both teams for all PRs.

### Scope Note

Validation of CODEOWNERS files in complyctl, complytime-providers, and
complytime-policies is out of scope for `config_test.go` in this repository.
Each repository's own CI pipeline is responsible for validating its CODEOWNERS
file. The `config_test.go` in this repo only validates the `.github/CODEOWNERS`
file within this repository.
