## ADDED Requirements

### Requirement: Field ownership boundary defined and enforced

The following field ownership boundary SHALL be enforced between peribolos and
safe-settings. Neither tool SHALL manage fields owned by the other.

**Peribolos owns** (via `peribolos.yaml` repo definitions):
- `description`
- `has_projects`
- `default_branch`

**Safe-settings owns** (via `safe-settings/` config):
- `allow_auto_merge`
- `delete_branch_on_merge`
- `allow_squash_merge`
- `allow_merge_commit`
- `allow_rebase_merge`
- `allow_update_branch`
- `has_wiki`
- `has_issues` (reserved; not actively managed in initial deployment)
- Security settings (vulnerability alerts, automated fixes)
- Branch protection rules
- Rulesets
- Labels, milestones, autolinks

**Neither tool manages**: `homepage`, `topics`, `visibility`/`private`
(set at repo creation, rarely changed).

#### Scenario: Safe-settings config does not set peribolos-owned fields

- **GIVEN** the safe-settings config files exist under `safe-settings/`
- **WHEN** the boundary validation tests run
- **THEN** no safe-settings config file (settings.yml, suborg files, repo
  files) sets `description`, `has_projects`, or `default_branch` under
  the `repository` key

#### Scenario: Peribolos config does not set safe-settings-owned fields

- **GIVEN** `peribolos.yaml` defines repos with settings
- **WHEN** the boundary validation tests run
- **THEN** no repo definition in `peribolos.yaml` sets `has_wiki`,
  `has_issues`, `allow_auto_merge`, `delete_branch_on_merge`,
  `allow_squash_merge`, `allow_merge_commit`, `allow_rebase_merge`, or
  `allow_update_branch`

### Requirement: Suborg repos exist in peribolos.yaml

All repositories listed in safe-settings suborg files (`suborgs/*.yml`)
SHALL exist in the `peribolos.yaml` repos section. This ensures safe-settings
does not reference repos that are not managed by the organization.

#### Scenario: Suborg references a repo not in peribolos.yaml

- **GIVEN** a suborg file lists repo `nonexistent-repo` in `suborgrepos`
- **AND** `nonexistent-repo` does not exist in `peribolos.yaml` repos
- **WHEN** the boundary validation tests run
- **THEN** the test fails with an error identifying the unknown repo

### Requirement: No repo appears in multiple suborg files

A repository SHALL NOT appear in more than one suborg configuration file.
Each repo belongs to exactly one suborg group (or none, inheriting only
org-wide defaults).

#### Scenario: Repo listed in two suborg files

- **GIVEN** `code-repos.yml` lists `complyctl` in `suborgrepos`
- **AND** `non-code-repos.yml` also lists `complyctl` in `suborgrepos`
- **WHEN** the boundary validation tests run
- **THEN** the test fails with an error identifying the duplicate assignment

### Requirement: Boundary tests in config/boundary_test.go

All boundary validation logic SHALL be implemented as Go tests in
`config/boundary_test.go`. These tests SHALL:
- Parse `peribolos.yaml` to extract the repo list and per-repo fields.
  The peribolos YAML structure is `orgs.<orgname>.repos.<reponame>` with
  per-repo fields at that level. Safe-settings uses a `repository` key in
  `settings.yml` and suborg files, and repo-level overrides under
  `safe-settings/repos/<name>.yml`.
- Parse all YAML files under `safe-settings/` to extract configured fields
- Validate the three boundary rules above (no field overlap, suborg repos
  exist, no duplicate suborg membership)

The tests SHALL be runnable locally via `make test-unit` and SHALL run in
CI on every PR via the existing `validate-peribolos.yml` workflow (or an
equivalent validation workflow).

#### Scenario: Boundary tests run on PR

- **GIVEN** a PR modifies `peribolos.yaml` or any file under `safe-settings/`
- **WHEN** the CI validation workflow runs
- **THEN** `config/boundary_test.go` tests execute and report pass/fail
- **AND** the PR cannot merge if boundary tests fail

#### Scenario: Boundary tests pass with correct config

- **GIVEN** `peribolos.yaml` defines repos with only `description`,
  `has_projects`, and `default_branch`
- **AND** safe-settings config defines only non-overlapping fields
- **AND** all suborg repos exist in `peribolos.yaml`
- **AND** no repo appears in multiple suborgs
- **WHEN** the boundary validation tests run
- **THEN** all tests pass

### Requirement: Suborg repo lists match ruleset repository conditions

All repositories listed in suborg files (`suborgs/*.yml` via `suborgrepos`)
SHALL match the corresponding `repository_name.include` lists in the
`settings.yml` rulesets. This prevents a repo from getting suborg settings
but missing the corresponding ruleset (or vice versa).

#### Scenario: Suborg repo missing from ruleset condition

- **GIVEN** `code-repos.yml` lists `new-repo` in `suborgrepos`
- **AND** `settings.yml` `code-repos-default-branch` ruleset does not
  include `new-repo` in `repository_name.include`
- **WHEN** the boundary validation tests run
- **THEN** the test fails identifying the missing repo

### Requirement: Boundary tests cover repo-level override files

Boundary validation SHALL parse all YAML files under `safe-settings/repos/`
in addition to `settings.yml` and suborg files. A repo-level override file
SHALL NOT set peribolos-owned fields.

#### Scenario: Repo override sets peribolos-owned field

- **GIVEN** `safe-settings/repos/example.yml` sets `description` under
  `repository`
- **WHEN** the boundary validation tests run
- **THEN** the test fails identifying the field and file
