## ADDED Requirements

### Requirement: Auto-merge enabled org-wide

The org-wide `settings.yml` SHALL set `allow_auto_merge: true` for all
repositories (unless overridden at suborg or repo level).

#### Scenario: New repo inherits auto-merge setting

- **GIVEN** the org-wide settings define `allow_auto_merge: true`
- **WHEN** a new repository is created in the complytime org
- **THEN** safe-settings applies `allow_auto_merge: true` to the repo

### Requirement: Auto-delete merged branches enabled org-wide

The org-wide `settings.yml` SHALL set `delete_branch_on_merge: true` for all
repositories (unless overridden at suborg or repo level).

#### Scenario: Merged branch auto-deleted

- **GIVEN** the org-wide settings define `delete_branch_on_merge: true`
- **WHEN** a pull request is merged in any managed repository
- **THEN** the source branch is automatically deleted

### Requirement: Merge strategies defined org-wide

The org-wide `settings.yml` SHALL define the following merge strategy defaults:
- `allow_squash_merge: true`
- `allow_merge_commit: true`
- `allow_rebase_merge: true`
- `allow_update_branch: true`

#### Scenario: All merge strategies available

- **GIVEN** the org-wide settings define all merge strategies as enabled
- **WHEN** a repository is managed by safe-settings
- **THEN** all three merge strategies (squash, merge commit, rebase) are
  available for pull requests

### Requirement: Security settings enabled org-wide

The org-wide `settings.yml` SHALL enable:
- `security.enableVulnerabilityAlerts: true`
- `security.enableAutomatedSecurityFixes: true`

#### Scenario: Vulnerability alerts enabled on all repos

- **GIVEN** the org-wide settings enable vulnerability alerts
- **WHEN** safe-settings applies settings to a repository
- **THEN** Dependabot vulnerability alerts are enabled
- **AND** automated security fixes (Dependabot PRs) are enabled

### Requirement: Wiki disabled org-wide

The org-wide `settings.yml` SHALL set `has_wiki: false` for all repositories,
since documentation is maintained in dedicated repositories and wiki content
is not version-controlled.

#### Scenario: Wiki disabled on managed repos

- **GIVEN** the org-wide settings define `has_wiki: false`
- **WHEN** safe-settings applies settings to a repository
- **THEN** the wiki tab is disabled on that repository

### Requirement: Suborg grouping for code vs non-code repos

Two suborg configuration files SHALL be defined:

1. `code-repos.yml` — applies to repositories containing source code:
   complyctl, complytime-providers, complytime-policies,
   complytime-collector-components, org-infra

   Excluded: `complyscribe` (archived) and `gemara-content-service` (pending archival).

2. `non-code-repos.yml` — applies to repositories without source code:
   community, complytime-demos, website, complytime

Each suborg file SHALL use `suborgrepos` to list the repos in that group.

#### Scenario: Code repo gets code-specific settings

- **GIVEN** `code-repos.yml` defines stricter settings for code repos
- **WHEN** safe-settings applies settings to `complyctl`
- **THEN** the code-repo-specific settings are merged on top of org-wide
  defaults

#### Scenario: Non-code repo gets lighter settings

- **GIVEN** `non-code-repos.yml` defines lighter settings for non-code repos
- **WHEN** safe-settings applies settings to `community`
- **THEN** the non-code-repo-specific settings are merged on top of org-wide
  defaults

### Requirement: Safe-settings SHALL NOT manage peribolos-owned fields

Safe-settings config files SHALL NOT set fields owned by peribolos. See
the `tool-boundary-enforcement` spec for the authoritative field ownership
list and enforcement details.
