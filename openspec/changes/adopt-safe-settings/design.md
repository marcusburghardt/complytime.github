## Context

The complytime GitHub organization uses peribolos for declarative org management
(membership, teams, team-repo permissions) via `peribolos.yaml` in the `.github`
repo. However, repository-level settings (branch protection, rulesets,
auto-merge, security configurations) are managed manually through the GitHub UI.
This creates configuration drift, inconsistent security posture across repos,
and no audit trail for changes.

A security review of the `.github` repo's access model (conducted during the
`restructure-teams-and-codeowners` change) identified that branch protection
rules and rulesets are critical security controls that should be managed as code,
with the same PR-review-and-apply workflow used for peribolos.

safe-settings (github/safe-settings, ~870 stars, ISC license) is a GitHub-built
policy-as-code tool that manages repository settings, branch protections,
rulesets, and more from a centralized YAML config. It complements peribolos by
covering the areas peribolos does not manage.

## Goals / Non-Goals

**Goals:**
- Manage repository settings (auto-merge, delete-branch-on-merge, merge
  strategies, security settings) as code across all complytime repos
- Manage branch protection rules and rulesets as code, replacing UI-managed
  rules
- Prevent configuration drift via scheduled GitOps convergence
- Enforce a clear tool boundary between peribolos and safe-settings with
  automated validation guardrails
- Enable local testing and dry-run workflows mirroring the peribolos pattern
- Prevent weakening of org-level protections through override validators
- Maintain clean tool boundary: peribolos = people/teams,
  safe-settings = repo/branch settings

**Non-Goals:**
- Replacing peribolos for org membership or team management
- Managing team-to-repo permissions via safe-settings (peribolos owns this)
- Managing repository descriptions or default_branch via safe-settings
  (peribolos owns these via its repo definitions)
- Achieving full coverage on day one — start with the most critical settings
  (rulesets, auto-merge, delete-branch-on-merge) and expand incrementally

## Decisions

### 1. Separate GitHub App for safe-settings

Register a dedicated GitHub App (`safe-settings-bot` or similar) rather than
extending the existing `complytime-bot` used by peribolos.

**Rationale:** Peribolos requires `Organization: admin` and `Members: read/write`
— the most privileged GitHub API permissions. safe-settings does NOT need those.
Separate apps isolate blast radius: if one app's private key leaks, the attacker
can only affect that app's scope. Each app gets only the permissions it needs
(principle of least privilege).

**Permissions for safe-settings app:**
- Repository: Administration (write) — for managing repo settings, branch
  protection, rulesets
- Repository: Contents (read) — for reading config files from admin repo
- Repository: Checks (write) — for PR dry-run validation results
- Repository: Pull requests (write) — for PR comments with change previews
- Organization: Administration (read) — for reading org-level rulesets

**Alternative considered:** Extend complytime-bot. Rejected because it would
give the safe-settings workflow access to org admin permissions it does not need,
and a single key compromise would affect both org membership and repo settings.

### 2. GitHub Actions-only deployment

Deploy safe-settings via a GitHub Actions workflow that runs `npm run full-sync`
on three triggers:
- `push` to main — immediate convergence after config changes are merged
- `schedule` daily at 06:00 UTC — drift correction (30 min after peribolos
  sync at 05:30 UTC, ensuring membership/teams are applied before repo settings)
- `workflow_dispatch` — manual convergence on demand

No webhook listener, no hosting infrastructure, no public endpoint.

**Rationale:** The complytime org has ~12 repos, 3 admins, and ~24 members.
This is a small org where eventual consistency (daily sync) is acceptable.
The `push`-triggered sync provides near-immediate convergence after config
merges. This model matches the existing peribolos operational pattern
(scheduled + push + manual dispatch), requires zero infrastructure, and
eliminates the attack surface of a public webhook endpoint.

**Alternative considered:** Webhook-driven deployment (Docker/Lambda) for
real-time drift prevention and PR dry-run validation. Rejected because it
adds infrastructure hosting, monitoring, additional secrets (WEBHOOK_SECRET,
CLIENT_ID, CLIENT_SECRET), and operational burden disproportionate to the
org's size. Can be adopted later if the org grows significantly or real-time
enforcement becomes a hard requirement.

### 3. Config in `.github` repo with CONFIG_PATH override

Store safe-settings config in the existing `.github` repo under a
`safe-settings/` directory at the repository root, using `ADMIN_REPO=.github`
and `CONFIG_PATH=safe-settings`.

**Rationale:** Centralizes all org management config in one repo. The `.github`
repo already has admin-only CODEOWNERS, required status checks, required
signatures, and no bypass actors — the same security model applies to
safe-settings config files automatically.

**Directory structure:**
```
<repo root>/
├── peribolos.yaml                     # peribolos (existing, at root)
├── safe-settings/                     # NEW: safe-settings config
│   ├── settings.yml                   # org-wide repo defaults
│   ├── deployment-settings.yml        # runtime config (restricted repos)
│   ├── suborgs/
│   │   ├── code-repos.yml             # complyctl, providers, policies, etc.
│   │   └── non-code-repos.yml         # community, website, demos
│   └── repos/                         # per-repo overrides (only if needed)
│       └── complyctl.yml              # complyctl: 2 required approvers
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       ├── apply_peribolos.yml        # existing
│       └── safe_settings_sync.yml     # NEW: primary sync workflow
```

**Alternative considered:** Dedicated `admin` repo. Rejected because it splits
the org management config across two repos with separate access controls and
review workflows. Keeping everything in `.github` simplifies governance.

### 4. Suborg groupings: code repos vs non-code repos

Define two suborgs to apply different policies:
- `code-repos`: complyctl, complytime-providers, complytime-policies,
  complytime-collector-components,
  org-infra — strict branch protection, required reviews (required signatures deferred to follow-up after contributor onboarding).
  Excluded: `complyscribe` (archived) and `gemara-content-service` (pending archival).
- `non-code-repos`: community, complytime-demos, website, complytime — lighter
  protection, fewer required checks

**Rationale:** Code repos need strict security controls (signed commits,
required reviews, status checks). Non-code repos benefit from auto-merge and
simpler review processes. The suborg model allows org-wide defaults with
group-specific overrides without per-repo config files.

### 5. `.github` repo ruleset remains manually managed

The `.github` repo currently has a manually-created ruleset named "verifiy"
(sic) managed via the GitHub UI. Since the `.github` repo is excluded from
safe-settings management (decision #7), this ruleset stays manually managed.

The typo SHALL be corrected from "verifiy" to "verify" via the GitHub UI as a
one-time fix. This is a deliberate exception: the admin repo's own ruleset
should not be subject to circular self-management by a tool it hosts.

### 6. Override validators for security floor

Configure `overridevalidators` in `deployment-settings.yml` to prevent suborg
or repo level settings from weakening org-level protections. Specifically:
- Required approving review count cannot be lowered below the org default
- Branch protection cannot be disabled at repo level
- Required signatures cannot be removed

**Rationale:** Without validators, any repo-level config file could override
org-level branch protection to zero approvers. Validators enforce a security
floor that cannot be weakened by lower-level config.

### 7. Exclude `.github` and `admin` repos from safe-settings management

Configure `deployment-settings.yml` to exclude the `.github` repo itself from
safe-settings management. The `.github` repo's settings and rulesets are
managed manually via the GitHub UI. safe-settings should not manage its own
admin repo's settings to avoid circular dependency issues.

### 8. Tool boundary enforcement with automated guardrails

Define a clear, enforceable boundary between peribolos and safe-settings:

**Peribolos owns** (via `peribolos.yaml`):
- Org membership (admins, members)
- Team creation, membership, privacy, and descriptions
- Team-to-repo permission mappings
- Per-repo: `description`, `has_projects`, `default_branch`

**Safe-settings owns** (via `safe-settings/`):
- Per-repo: `allow_auto_merge`, `delete_branch_on_merge`, `allow_squash_merge`,
  `allow_merge_commit`, `allow_rebase_merge`, `allow_update_branch`,
  `has_wiki`, `has_issues`
- Security settings (vulnerability alerts, automated fixes)
- Branch protection rules
- Organization-level and repo-level rulesets
- Labels, milestones, autolinks

**Neither tool manages**: `homepage`, `topics`, `visibility`/`private`
(set at repo creation time, rarely changed).

**Enforcement:** Go tests in `config/boundary_test.go` validate:
1. All repos listed in suborg files exist in `peribolos.yaml`
2. No repo appears in multiple suborg files
3. Safe-settings config does not set fields owned by peribolos
   (`description`, `has_projects`, `default_branch`)
4. Peribolos config does not set fields owned by safe-settings
   (`has_wiki`, `allow_auto_merge`, `delete_branch_on_merge`, etc.)

These tests run on every PR via CI as guardrails against accidental overlap.

**Rationale:** Both tools can technically manage overlapping repository fields.
Without enforcement, divergent settings cause a flapping loop where each tool
reverts the other's changes. Automated tests prevent this at PR review time.

### 9. Local development workflow

Provide Makefile targets for safe-settings that mirror the existing peribolos
local testing pattern:
- `make safe-settings-validate` — yamllint on all safe-settings YAML files
- `make safe-settings-dryrun` — run `npm run full-sync` in dry-run mode against
  the live org (requires Node.js and a GitHub token)
- `make ensure-safe-settings` — clone safe-settings and install dependencies

**Rationale:** Maintainers must be able to validate and test config changes
locally before pushing. The peribolos Makefile targets (`peribolos-dryrun`,
`peribolos-apply`) have proven effective and should be replicated.

### 10. Maintainer documentation

Create a `MAINTAINING.md` at the repository root covering both peribolos and
safe-settings workflows:
- Tool boundary and field ownership table
- How to add/remove org members (peribolos)
- How to add a new repo to safe-settings management
- How to change branch protection rules or rulesets
- How to add repo-specific overrides
- How to run local dry-runs for both tools
- How to debug when settings are not applied
- Override validator policies and how to request exceptions

Link from `README.md` to `MAINTAINING.md`. Keep `README.md` focused on
project overview and prerequisites.

## Risks / Trade-offs

**[Eventual consistency]** The GHA-only deployment provides daily convergence,
not real-time enforcement. Manual UI changes to repo settings persist until
the next scheduled sync or a manual `workflow_dispatch` trigger.
-> Mitigation: The `push` trigger on main provides near-immediate convergence
after config merges. Daily scheduled sync catches drift from manual UI changes.
Acceptable for a small org (~12 repos) where admins are disciplined about
config-as-code workflows.

**[Two tools for org management]** Maintaining peribolos AND safe-settings
increases operational complexity. Two config schemas, two deployment pipelines,
two sets of secrets.
-> Mitigation: Clean boundary (people vs settings) enforced by automated Go
tests and CI guardrails. Both tools are YAML-based GitOps. `MAINTAINING.md`
documents the boundary. The alternative (Terraform) is a single tool but
with significantly higher operational overhead (state management).

**[safe-settings maturity]** Open issues on the repo. Some edge cases may
require workarounds.
-> Mitigation: Start with well-documented features (rulesets, repo settings).
Avoid less-tested features initially. The project is actively maintained by
GitHub staff.

**[Node.js dependency]** Introduces a Node.js runtime dependency into an
otherwise Go-based ecosystem.
-> Mitigation: Contained to the GHA runner and local development. Does not
affect application code. Local testing requires `node` and `npm`.

**[Overlap with peribolos]** Both tools can manage overlapping repository
fields (description, has_projects, has_wiki, merge strategies). Running both
without boundary enforcement causes flapping.
-> Mitigation: Field ownership defined in decision #8. Automated Go tests in
`config/boundary_test.go` validate no overlap exists. CI runs these tests on
every PR as guardrails. `MAINTAINING.md` documents which tool owns which
fields.
