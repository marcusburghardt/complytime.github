## 1. Fix Authentication and Pipeline

- [x] 1.1 Replace `APP_ACCESS_TOKEN` with `actions/create-github-app-token` (SHA-pinned) in `apply_peribolos.yml`: add token generation step using `secrets.COMPLYTIME_BOT_CLIENT_ID` and `secrets.COMPLYTIME_BOT_PRIVATE_KEY` scoped to `owner: complytime`
- [x] 1.2 Update the Peribolos execution step to use the generated token via safe file writing (`env:` block, not inline expansion), add `--require-self=false` flag, and ensure `--min-admins 2` is present
- [x] 1.3 Add `set -o pipefail` to the Peribolos execution step to fix silent failure masking
- [x] 1.4 Remove ghproxy build, download, and sidecar process from the workflow (not used by Peribolos)
- [x] 1.5 ~~Add unconditional token file cleanup step~~ Eliminated by using process substitution — no credentials written to disk
- [x] 1.6 Add explicit `permissions:` block at the job level with minimal scopes

## 2. Add Workflow Triggers

- [x] 2.1 Add `workflow_dispatch` trigger with a `dry-run` boolean input (default: `false`) to `apply_peribolos.yml`
- [x] 2.2 Add `schedule` trigger with daily cron expression (e.g., `cron: '30 6 * * *'`) to `apply_peribolos.yml`
- [x] 2.3 Conditionally include or exclude `--confirm` flag based on the `dry-run` input; ensure `pull_request` events skip the apply step (preserve existing guard) and `schedule`/`push`/`dispatch` events proceed with apply
- [x] 2.4 Add `concurrency` group to prevent simultaneous Peribolos execution across trigger types

## 3. Fix Config and Tests

> Note: Task 3.3 depends on 3.1 and 3.2 being completed first. Wiring `testTeamMembers()` before fixing the config will cause immediate test failures because it validates that org admins are not listed as team members.

- [x] 3.1 Remove the orphan `docs:` key from `peribolos.yaml`
- [x] 3.2 Move `jpower432` and `marcusburghardt` from `members:` to `maintainers:` in teams where they are org admins (`complytime-approvers`, `complytime-dev`, `openscap-plugin-approvers`)
- [x] 3.3 Wire `testTeamMembers()` into `TestOrgs()` in `config/config_test.go` so team config validation actually runs [depends: 3.1, 3.2]
- [x] 3.4 Run `go test ./config/...` to verify tests pass with the corrected config

## 4. Drift Detection Workflow

- [x] 4.1 Create `.github/workflows/drift_detection.yml` with a weekly cron schedule (e.g., `cron: '30 5 * * 1'`) and explicit `permissions: { contents: read, issues: write }`
- [x] 4.2 Implement drift detection: generate installation token for `peribolos --dump complytime`, normalize output, and diff against `peribolos.yaml`
- [x] 4.3 Implement issue management: use `GITHUB_TOKEN` (not App token) to create/update issues with label `peribolos-drift`, wrap diff output in fenced code block for safe rendering, update existing open issue if one exists

## 5. Validation

- [x] 5.1 Run the validation workflow (`go test ./config/...`) to confirm all config and test changes are correct
- [x] 5.2 Verify the apply workflow YAML has no references to `APP_ACCESS_TOKEN` or ghproxy, has SHA-pinned action references, and declares explicit permissions

<!-- spec-review: passed -->
