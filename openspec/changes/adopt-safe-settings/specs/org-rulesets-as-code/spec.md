## ADDED Requirements

### Requirement: Default branch ruleset for code repos

An org-level ruleset SHALL be defined in `settings.yml` that applies to the
default branch of all code repositories. The ruleset SHALL enforce:

- `type: deletion` — prevent branch deletion
- `type: non_fast_forward` — prevent force pushes
- `type: required_signatures` — require signed commits (SHOULD; deferred until contributor GPG/SSH signing onboarding is complete. Omitted from initial deployment.)
- `type: pull_request` with parameters:
  - `dismiss_stale_reviews_on_push: true`
  - `require_code_owner_review: true`
  - `require_last_push_approval: true`
  - `required_approving_review_count: 1`
  - `required_review_thread_resolution: false` (matches current org state; can be tightened as a follow-up)

The ruleset SHALL target `~DEFAULT_BRANCH` and SHALL include code repos via
`repository_name` conditions.

The ruleset SHALL NOT define bypass actors. All users, including org
admins, follow the same rules.

#### Scenario: Code repo default branch protected

- **GIVEN** the org-level ruleset is defined in safe-settings config
- **WHEN** safe-settings applies the ruleset
- **THEN** all code repos have the default branch protected with
  required reviews and no force pushes

#### Scenario: Admin cannot bypass rules

- **GIVEN** the ruleset has no bypass actors
- **WHEN** an org admin attempts to force push to the default branch
- **THEN** the push is rejected

### Requirement: Lighter ruleset for non-code repos

A separate ruleset SHALL be defined for non-code repositories with lighter
requirements. This ruleset SHALL enforce:

- `type: deletion` — prevent branch deletion
- `type: non_fast_forward` — prevent force pushes
- `type: pull_request` with parameters:
  - `required_approving_review_count: 1`
  - `required_review_thread_resolution: true`

Required signatures and code owner review MAY be omitted for non-code repos
at the admin's discretion.

#### Scenario: Non-code repo has lighter protection

- **GIVEN** the non-code repo ruleset is defined
- **WHEN** safe-settings applies the ruleset to `community`
- **THEN** the repo requires a PR with 1 approval but does not require
  signed commits or code owner review

### Requirement: Fix existing "verifiy" ruleset on .github repo

The manually-created "verifiy" ruleset on the `.github` repo SHALL be renamed
to "verify" via the GitHub UI as a one-time manual fix. This ruleset remains
manually managed because the `.github` repo is excluded from safe-settings
management via `deployment-settings.yml` to avoid circular dependency.

The `.github` repo's ruleset is a deliberate exception to config-as-code
management. Its configuration (required reviews, stale review dismissal,
last push approval, required status checks, signatures) SHALL be preserved
during the rename.

#### Scenario: Ruleset renamed without parameter changes

- **GIVEN** the `.github` repo has a ruleset named "verifiy"
- **WHEN** an admin renames it to "verify" via the GitHub UI
- **THEN** all existing rule parameters remain unchanged
- **AND** the ruleset continues to protect the default branch

### Requirement: Required status checks configurable per repo

Rulesets SHALL support per-repo required status checks via the suborg or repo
level config. For example, `complyctl` may require different CI checks than
`complytime-providers`.

Status checks that are defined outside of safe-settings SHALL use the
`{{EXTERNALLY_DEFINED}}` placeholder to preserve existing checks configured
via the GitHub UI or other tools.

#### Scenario: Repo-specific status checks preserved

- **GIVEN** a repo has status checks configured outside of safe-settings
- **AND** the safe-settings config uses `{{EXTERNALLY_DEFINED}}`
- **WHEN** safe-settings applies the ruleset
- **THEN** the existing status checks are preserved and not overwritten
