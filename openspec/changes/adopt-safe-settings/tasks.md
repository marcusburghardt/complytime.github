## Phase 1: GitHub App Setup

- [ ] 1.1 Register a new GitHub App (`safe-settings-bot`) in the complytime org with permissions: Repository Administration (write), Contents (read), Checks (write), Pull requests (write), Organization Administration (read)
- [ ] 1.2 Install the app on the complytime org, granting access to all repositories
- [ ] 1.3 Store `SAFE_SETTINGS_APP_ID` as a repository variable and `SAFE_SETTINGS_PRIVATE_KEY` as a repository secret in the `.github` repo (no CLIENT_ID/CLIENT_SECRET needed for GHA-only deployment)

## Phase 2: Config Structure

- [ ] 2.1 Create `safe-settings/` directory at the repository root (not under `.github/`)
- [ ] 2.2 Create `safe-settings/deployment-settings.yml` with `restrictedRepos` excluding `.github`, `admin`, and `safe-settings` repos, and define `overridevalidators` and `configvalidators`
- [ ] 2.3 Create `safe-settings/settings.yml` with org-wide defaults: `allow_auto_merge: true`, `delete_branch_on_merge: true`, merge strategies, `has_wiki: false`, security settings (vulnerability alerts, automated fixes) — SHALL NOT include peribolos-owned fields (`description`, `has_projects`, `default_branch`)
- [ ] 2.4 Define org-level rulesets in `safe-settings/settings.yml` for code repos: deletion protection, non-fast-forward, required signatures, PR requirements (dismiss stale reviews, code owner review, last push approval, 1 required approver, thread resolution)
- [ ] 2.5 Create `safe-settings/suborgs/code-repos.yml` with `suborgrepos` listing: complyctl, complytime-providers, complytime-policies, complyscribe, complytime-collector-components, gemara-content-service, org-infra
- [ ] 2.6 Create `safe-settings/suborgs/non-code-repos.yml` with `suborgrepos` listing: community, complytime-demos, website, complytime — lighter ruleset (no required signatures, no code owner review)
- [ ] 2.7 Rename the `.github` repo's "verifiy" ruleset to "verify" via the GitHub UI (one-time manual fix; this ruleset remains manually managed)

## Phase 3: Deployment (GitHub Actions)

- [ ] 3.1 Create `safe_settings_sync.yml` workflow in `.github/workflows/` with triggers: `push` to main, daily `schedule` at 06:00 UTC, `workflow_dispatch`
- [ ] 3.2 Configure the workflow to check out both the `.github` repo and `github/safe-settings` at a pinned version tag
- [ ] 3.3 Configure the workflow to run `npm install` and `npm run full-sync` with env vars: `APP_ID`, `PRIVATE_KEY`, `GH_ORG=complytime`, `ADMIN_REPO=.github`, `CONFIG_PATH=safe-settings`, `DEPLOYMENT_CONFIG_FILE`
- [ ] 3.4 Add a concurrency group to prevent concurrent sync runs
- [ ] 3.5 Test workflow: trigger `workflow_dispatch`, verify settings are applied to managed repos

## Phase 4: Dry-Run Validation

- [ ] 4.1 Run safe-settings in dry-run mode against all repos to compare declared config vs current GitHub state (via `workflow_dispatch` or local `make safe-settings-dryrun`)
- [ ] 4.2 Review the output — identify any unexpected changes that would be applied
- [ ] 4.3 Adjust config to match desired state (not current state, if current state is wrong)

## Phase 5: Apply and Verify

- [ ] 5.1 Merge the safe-settings config to main — verify push-triggered sync applies settings to all managed repos
- [ ] 5.2 Verify org-level rulesets are created and applied to the correct repos
- [ ] 5.3 Verify repo settings (auto-merge, delete-branch-on-merge, wiki disabled) are applied
- [ ] 5.4 Test drift correction: manually change a repo setting via UI, trigger `workflow_dispatch`, verify safe-settings reverts it
- [ ] 5.5 Test override validator: merge a config that lowers required approvers below org default, verify the sync rejects the change

## Phase 6: Validation and Guardrails

- [ ] 6.1 Create `config/boundary_test.go` with Go tests that validate: all suborg repos exist in `peribolos.yaml`, no repo in multiple suborgs, no safe-settings config sets peribolos-owned fields, no peribolos config sets safe-settings-owned fields
- [ ] 6.2 Extend `make lint` to cover `safe-settings/**/*.yml` with yamllint (or add `make safe-settings-validate` target)
- [ ] 6.3 Update `validate-peribolos.yml` workflow (or create `validate-safe-settings.yml`) to run boundary tests on every PR touching `peribolos.yaml` or `safe-settings/**`
- [ ] 6.4 Verify boundary tests run and pass in CI before any PR can merge

## Phase 7: Local Development

- [ ] 7.1 Add `ensure-safe-settings` Makefile target — clone `github/safe-settings` at a pinned version and run `npm install` (idempotent, mirrors `ensure-peribolos`)
- [ ] 7.2 Add `safe-settings-validate` Makefile target — run yamllint on all `safe-settings/**/*.yml` files
- [ ] 7.3 Add `safe-settings-dryrun` Makefile target — run `npm run full-sync` locally with credentials from `~/.config/safe-settings/env` or environment variables
- [ ] 7.4 Update `make sanity` to include safe-settings YAML validation

## Phase 8: Documentation

- [ ] 8.1 Create `MAINTAINING.md` at repo root covering: tool boundary table, common workflows (add member, change rulesets, add repo to safe-settings, add override), local testing instructions, troubleshooting guide, override validator policies
- [ ] 8.2 Update `README.md` to link to `MAINTAINING.md` for maintainer documentation
- [ ] 8.3 Update `.github/CODEOWNERS` if path-specific rules are needed for `safe-settings/` directory
