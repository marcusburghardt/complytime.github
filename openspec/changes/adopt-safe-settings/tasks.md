## Phase 1: GitHub App Setup

- [ ] 1.1 Register a new GitHub App (`safe-settings-bot`) in the complytime org with permissions: Repository Administration (write), Contents (read), Checks (write), Pull requests (write), Organization Administration (read and write)
- [ ] 1.2 Install the app on the complytime org, granting access to all repositories
- [ ] 1.3 Store `SAFE_SETTINGS_APP_ID` as a repository variable and `SAFE_SETTINGS_PRIVATE_KEY` as a repository secret in the `.github` repo (no CLIENT_ID/CLIENT_SECRET needed)

## Phase 2: Config Structure

- [ ] 2.1 Create `safe-settings/` directory at the repository root (not under `.github/`)
- [ ] 2.2 Create `safe-settings/deployment-settings.yml` with `restrictedRepos` excluding `.github`, `admin`, and `safe-settings` repos, and define `overridevalidators` and `configvalidators`
- [ ] 2.3 Create `safe-settings/settings.yml` with org-wide defaults: `allow_auto_merge: true`, `delete_branch_on_merge: true`, merge strategies, `has_wiki: false`, security settings (vulnerability alerts, automated fixes) — SHALL NOT include peribolos-owned fields (`description`, `has_projects`, `default_branch`)
- [ ] 2.4 Define org-level rulesets in `safe-settings/settings.yml` for code repos: deletion protection, non-fast-forward, PR requirements (dismiss stale reviews, code owner review, last push approval, 1 required approver)
- [ ] 2.5 Create `safe-settings/suborgs/code-repos.yml` with `suborgrepos` listing: complyctl, complytime-collector-components, complytime-policies, complytime-providers, org-infra
- [ ] 2.6 Create `safe-settings/suborgs/non-code-repos.yml` with `suborgrepos` listing: community, complytime-demos, website, complytime — lighter ruleset (no code owner review)
- [ ] 2.7 Rename the `.github` repo's "verifiy" ruleset to "verify" via the GitHub UI (one-time manual fix; this ruleset remains manually managed)

## Phase 3: Deployment (GitHub Actions)

- [ ] 3.1 Create `safe_settings_sync.yml` workflow in `.github/workflows/` with `workflow_dispatch` trigger only (push/schedule triggers added after validation)
- [ ] 3.2 Add workflow inputs: `dry-run` (boolean, default true), `repos` (string, optional comma-separated repo filter)
- [ ] 3.3 Add workflow step to generate scoped `deployment-settings.yml` when `repos` input is provided (excludes all repos except targets)
- [ ] 3.4 Configure the workflow to check out both the `.github` repo and `github/safe-settings` at a pinned version
- [ ] 3.5 Configure the workflow to run `npm install` and `npm run full-sync` with env vars: `APP_ID`, `PRIVATE_KEY`, `GH_ORG=complytime`, `ADMIN_REPO=.github`, `CONFIG_PATH=safe-settings`, `DEPLOYMENT_CONFIG_FILE`, `FULL_SYNC_NOP`
- [ ] 3.6 Add concurrency group, timeout (15 min), and YAML pre-validation step

## Phase 4: Validation and Guardrails

- [ ] 4.1 Create `config/boundary_test.go` with Go tests that validate: all suborg repos exist in `peribolos.yaml`, no repo in multiple suborgs, no safe-settings config sets peribolos-owned fields, no peribolos config sets safe-settings-owned fields, suborg repo lists match ruleset conditions
- [ ] 4.2 Extend `make lint` to cover `safe-settings/**/*.yml` with yamllint (and add `make safe-settings-validate` target)
- [ ] 4.3 Update CI to run boundary tests on every PR touching `peribolos.yaml` or `safe-settings/**`
- [ ] 4.4 Verify boundary tests run and pass in CI before any PR can merge

## Phase 5: Merge and Initial Dry-Run

- [ ] 5.1 Merge the safe-settings config PR to main
- [ ] 5.2 Trigger `workflow_dispatch` with `dry-run=true` and `repos=complytime-demos` — review what would change
- [ ] 5.3 Adjust config if the dry-run reveals unexpected changes, re-merge, re-run

## Phase 6: Incremental Apply and Verify

- [ ] 6.1 Trigger `workflow_dispatch` with `dry-run=false` and `repos=complytime-demos` — apply to one repo
- [ ] 6.2 Verify repo settings and rulesets in the GitHub UI for `complytime-demos`
- [ ] 6.3 Repeat for each repo group: expand `repos` to include more repos progressively
- [ ] 6.4 Trigger `workflow_dispatch` with `dry-run=false` and `repos` empty — apply to all managed repos
- [ ] 6.5 Verify org-level rulesets are created and applied to the correct repos
- [ ] 6.6 Verify repo settings (auto-merge, delete-branch-on-merge, wiki disabled) are applied
- [ ] 6.7 Test drift correction: manually change a repo setting via UI, trigger `workflow_dispatch`, verify safe-settings reverts it
- [ ] 6.8 Test override validator: merge a config that lowers required approvers below org default, verify the sync rejects the change
- [ ] 6.9 Delete legacy repo-level rulesets (listed in settings.yml migration notes) after verifying org-level rulesets work correctly

## Phase 7: Documentation

- [ ] 7.1 Create `MAINTAINING.md` at repo root covering: tool boundary table, common workflows (add member, change rulesets, add repo to safe-settings, add override), local validation instructions, workflow_dispatch usage, troubleshooting guide, override validator policies
- [ ] 7.2 Update `README.md` to link to `MAINTAINING.md` for maintainer documentation
- [ ] 7.3 Update `.github/CODEOWNERS` to add path-specific rules for `safe-settings/` requiring admin approval

## Phase 8: Enable Automation (future change)

- [ ] 8.1 Add `push` trigger on `safe-settings/**` path changes to main
- [ ] 8.2 Add `schedule` trigger (daily at 06:00 UTC, 30 min after peribolos) for drift correction
- [ ] 8.3 Verify automated triggers work correctly
<!-- spec-review: passed -->
