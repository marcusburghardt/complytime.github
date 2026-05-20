## Why

Peribolos manages org membership, teams, and team-repo permissions effectively,
but it cannot manage repository-level settings such as branch protection rules,
rulesets, auto-merge, auto-delete merged branches, or security configurations.
These settings are currently managed manually through the GitHub UI, leading to
configuration drift, inconsistency across repositories, and no audit trail for
changes. The complytime organization needs a centralized, GitOps-driven solution
to declare and enforce repository settings alongside the existing peribolos-based
org management.

## What Changes

- **Adopt github/safe-settings** as the policy-as-code tool for repository and
  org-level settings, complementing peribolos (which continues to manage org
  membership, team creation, and team membership).
- **Register a dedicated GitHub App** for safe-settings, separate from the
  existing complytime-bot used by peribolos, following the principle of least
  privilege and blast radius isolation.
- **Deploy safe-settings via GitHub Actions** with push-triggered sync,
  daily scheduled drift correction, and manual dispatch — no webhook
  infrastructure required.
- **Create centralized config** in the `.github` repo with org-wide defaults,
  suborg groupings (code repos vs non-code repos), and per-repo overrides where
  needed.
- **Define org-level rulesets** via safe-settings config for code and non-code
  repos. The `.github` repo's "verifiy" ruleset remains manually managed
  (renamed to "verify" via UI).
- **Define org-wide repository settings** including `allow_auto_merge: true`,
  `delete_branch_on_merge: true`, vulnerability alerts, and merge strategy
  defaults.
- **Configure override validators** to prevent repo-level or suborg-level
  overrides from weakening org-level protections (e.g., lowering required
  approver count).
- **Protect safe-settings config** via CODEOWNERS (admin-only approval) and
  the existing repository ruleset on the `.github` repo.

## Capabilities

### New Capabilities

- `safe-settings-deployment`: GitHub App registration and GitHub Actions sync
  workflow. Covers the operational foundation for running safe-settings.
- `org-wide-repo-settings`: Organization-wide default repository settings
  applied to all repos (auto-merge, delete-branch-on-merge, merge strategies,
  vulnerability alerts, wiki/projects toggles). Includes suborg-level groupings
  for code repos vs non-code repos.
- `org-rulesets-as-code`: Organization-level and repository-level rulesets
  managed as YAML config. Covers branch protection rules, required status
  checks, required signatures, PR review requirements, and bypass actor
  configuration.
- `settings-override-policy`: Custom validators that prevent suborg or repo
  level settings from weakening org-level protections. Covers override
  validation rules and enforcement behavior.
- `tool-boundary-enforcement`: Automated Go tests and CI guardrails that
  validate no field overlap between peribolos and safe-settings configs.
  Ensures suborg repo lists are consistent with peribolos.yaml.
- `local-development-workflow`: Makefile targets for local YAML validation
  and dry-run testing, mirroring the existing peribolos local testing pattern.
- `maintainer-documentation`: MAINTAINING.md covering both peribolos and
  safe-settings workflows, tool boundary, and troubleshooting.

### Modified Capabilities

(none -- no existing specs to modify)

## Impact

- **New GitHub App**: A `safe-settings-bot` (or similar) GitHub App registered
  in the complytime org with repository admin, contents read, checks write, and
  pull requests write permissions. Separate from the existing `complytime-bot`.
- **New secrets**: `SAFE_SETTINGS_APP_ID` (repository variable) and
  `SAFE_SETTINGS_PRIVATE_KEY` (repository secret) stored in the `.github`
  repo. No additional infrastructure secrets required.
- **No new infrastructure**: Runs entirely on GitHub Actions runners.
- **New config files**: `safe-settings/` directory in the `.github` repo with
  `settings.yml`, `deployment-settings.yml`, `suborgs/*.yml`, `repos/*.yml`.
- **CODEOWNERS update**: The `.github/CODEOWNERS` may need path-specific rules
  to protect `safe-settings/` config files.
- **Existing ruleset fix**: The "verifiy" ruleset on the `.github` repo is
  renamed to "verify" via the GitHub UI. It remains manually managed since the
  `.github` repo is excluded from safe-settings.
- **No peribolos impact**: Peribolos continues to manage org membership, team
  creation/membership, and team-to-repo permissions unchanged. A clear field
  ownership boundary is enforced by automated Go tests to prevent overlap.
- **New Go tests**: `config/boundary_test.go` validates cross-tool consistency
  (suborg repos exist in peribolos.yaml, no field overlap, no duplicate suborg
  membership). Runs on every PR as a CI guardrail.
- **New documentation**: `MAINTAINING.md` documents both tool workflows, field
  ownership, and troubleshooting. `README.md` links to it.
- **Node.js dependency**: safe-settings requires Node.js >= 18. This is
  contained to the GHA runner and local development. Does not affect the Go
  codebase.
