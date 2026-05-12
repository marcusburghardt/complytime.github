## ADDED Requirements

### Requirement: CODEOWNERS standardized to .github directory

All CODEOWNERS files across the complytime organization SHALL be located at
`.github/CODEOWNERS` within each repository. This follows GitHub's recommended
location and search priority order (`.github/`, root, `docs/`).

Reference:
https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

#### Scenario: This repo CODEOWNERS moved from root to .github

- **WHEN** the CODEOWNERS file is created at `.github/CODEOWNERS` in the
  `.github` repository
- **THEN** the root `CODEOWNERS` file SHALL be deleted and all ownership
  rules SHALL be defined in `.github/CODEOWNERS`

### Requirement: .github repo CODEOWNERS includes complytime-approvers team

The `.github` repository CODEOWNERS SHALL include both individual admin
users and the `@complytime/complytime-approvers` team as code owners for
all files. The format SHALL be:

```
* @jflowers @jpower432 @marcusburghardt @complytime/complytime-approvers
```

#### Scenario: Team and individual owners on same line

- **WHEN** a pull request is opened in the `.github` repository
- **THEN** review is requested from the individual admins and any member
  of the `complytime-approvers` team, and approval from any one of them
  satisfies the CODEOWNERS requirement

### Requirement: complyctl CODEOWNERS cleaned up

The complyctl repository CODEOWNERS SHALL be simplified to a single fallback
rule assigning `@complytime/complytime-dev` as the owner for all files. The
stale `/cmd/openscap-plugin/` rule and the `/cmd/complyctl/` specific rule
SHALL be removed.

#### Scenario: Stale openscap-plugin rule removed

- **WHEN** the complyctl CODEOWNERS is updated
- **THEN** there is no rule referencing `/cmd/openscap-plugin/` or
  `@complytime/openscap-plugin-approvers`

#### Scenario: Single fallback rule

- **WHEN** a pull request is opened in complyctl modifying any file
- **THEN** review is requested from `@complytime/complytime-dev`

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

#### Scenario: Provider-specific change triggers provider team review

- **WHEN** a pull request modifies files only under `/cmd/openscap-provider/`
- **THEN** review is requested from `@complytime/openscap-provider-approvers`
  only (last matching pattern takes precedence over the `*` fallback)

#### Scenario: Shared code change triggers dev team review

- **WHEN** a pull request modifies files under `/internal/` or root-level files
- **THEN** review is requested from `@complytime/complytime-dev`

#### Scenario: Cross-provider change triggers multiple teams

- **WHEN** a pull request modifies files in both `/cmd/openscap-provider/`
  and `/cmd/ampel-provider/`
- **THEN** review is requested from both `@complytime/openscap-provider-approvers`
  and `@complytime/ampel-provider-approvers`

### Requirement: complytime-policies CODEOWNERS created

The complytime-policies repository SHALL have a CODEOWNERS file at
`.github/CODEOWNERS` with a single fallback rule assigning both
`@complytime/complytime-policies-approvers` and `@complytime/complytime-dev`
as code owners for all files.

```
* @complytime/complytime-policies-approvers @complytime/complytime-dev
```

#### Scenario: Both teams requested for review

- **WHEN** a pull request is opened in complytime-policies modifying any file
- **THEN** review is requested from both `@complytime/complytime-policies-approvers`
  and `@complytime/complytime-dev`
