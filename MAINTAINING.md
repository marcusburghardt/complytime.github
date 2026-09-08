# Maintaining the complytime GitHub Organization

This document covers operational workflows for managing the complytime
GitHub organization using two complementary tools: **peribolos** and
**safe-settings**.

## Tool Boundary

| Area | Tool | Config Location |
|------|------|----------------|
| Org membership (admins, members) | peribolos | `peribolos.yaml` |
| Team creation, membership, privacy | peribolos | `peribolos.yaml` |
| Team-to-repo permission mappings | peribolos | `peribolos.yaml` |
| Repo description | peribolos | `peribolos.yaml` |
| Repo has_projects | peribolos | `peribolos.yaml` |
| Repo default_branch | peribolos | `peribolos.yaml` |
| Repo merge strategies | safe-settings | `safe-settings/settings.yml` |
| Repo auto-merge, delete-branch | safe-settings | `safe-settings/settings.yml` |
| Repo has_wiki | safe-settings | `safe-settings/settings.yml` |
| Dependabot alerts and fixes | safe-settings | `safe-settings/settings.yml` |
| Branch protection rules | safe-settings | `safe-settings/settings.yml` |
| Rulesets | safe-settings | `safe-settings/settings.yml` |
| `.github` repo ruleset | **manual** | GitHub UI |

**Why two tools?** Peribolos manages org-level concerns (who is a member,
what teams exist, what permissions teams have). Safe-settings manages
repo-level concerns (how branches are protected, what merge strategies
are allowed, what security features are enabled). This separation follows
the principle of least privilege for their respective GitHub App
permissions.

**Boundary enforcement:** Go tests in `config/boundary_test.go` validate
that neither tool manages fields owned by the other. These tests run on
every PR via CI.

## Common Workflows

### Add or Remove an Org Member

1. Edit `peribolos.yaml` — add/remove the username from the `admins` or
   `members` list (keep sorted alphabetically).
2. If adding, add to the appropriate team(s) as well.
3. Submit a PR. CI validates the config automatically.
4. After merge, peribolos applies the change (push-triggered or daily
   at 05:30 UTC).

### Enterprise-Managed Members

Some org members are provisioned by the GitHub Enterprise account via
IdP/SCIM enterprise teams rather than by peribolos. These users fall
into two categories:

**Not in any peribolos team** — remove them from `peribolos.yaml`
entirely. The `--ignore-enterprise-teams` flag (used by both the drift
and apply workflows) ensures peribolos ignores these users during
reconciliation. They stay in the org through the enterprise, and
peribolos neither adds nor removes them.

**Also in a peribolos-managed team** — keep them in `peribolos.yaml`
(the validation tests require team members to be org members) and add
their username to the `ENTERPRISE_MEMBERS_IGNORE` env variable in
`peribolos-drift.yml`. This filters out the expected
`UpdateOrgMembership` drift that `--ignore-enterprise-teams` causes
for these users.

To update the ignore list, edit the `ENTERPRISE_MEMBERS_IGNORE` value
in the "Run peribolos dry-run" step of `peribolos-drift.yml`. The
format is a comma-separated list of GitHub usernames:

```yaml
ENTERPRISE_MEMBERS_IGNORE: "user1, user2, user3"
```

**Why this drift happens:** `--ignore-enterprise-teams` subtracts
enterprise team members from peribolos' internal "have" set (current
GitHub state). If a user is also listed in `peribolos.yaml` (the
"want" set), peribolos sees "want but don't have" and generates an
`UpdateOrgMembership` mutation. The mutation is harmless (the user is
already a member) but it triggers a false-positive drift alert.

### Create a New Team or Change Team Membership

1. Edit `peribolos.yaml` — add/modify the team under the `teams` section.
2. Ensure team members are org members (CI validates this).
3. Ensure admins are listed as `maintainers`, not `members` (CI validates).
4. Submit a PR and merge.

### Evidence Locker MVP reviewers

`evidence-locker-mvp-reviewers` is the reviewer pool for issues and pull
requests whose milestone title is **Evidence Locker MVP** (or **Internal
Evidence Locker MVP**). Membership is the source of truth: change the
`members` list in `peribolos.yaml` to add or remove reviewers.

GitHub CODEOWNERS cannot filter on milestones, so assignment is done by
the org-infra workflow **Assign Evidence Locker MVP Reviewers** (see
`docs/MILESTONE_REVIEWERS.md` in `complytime/org-infra`). Native GitHub
code review auto-assignment is not used for this team.

### Add a New Repository to Safe-settings Management

1. Add the repo to `peribolos.yaml` with `description`, `has_projects`,
   and `default_branch` (peribolos-owned fields).
2. Add the repo to the appropriate suborg file:
   - `safe-settings/suborgs/code-repos.yml` for code repositories
   - `safe-settings/suborgs/non-code-repos.yml` for non-code repositories
3. Add the repo to the matching ruleset `repository_name.include` list
   in `safe-settings/settings.yml`. **Both files must be updated** — the
   suborg controls settings inheritance, the ruleset controls branch
   protection.
4. Add the repo to `safe-settings/deployment-settings.yml` under
   `restrictedRepos.include` so safe-settings manages it.
5. Submit a PR. CI boundary tests validate consistency.
6. After merge, the daily safe-settings sync (07:00 UTC) applies the
   change automatically. For immediate application, trigger a manual
   `workflow_dispatch` run.

### Change Branch Protection Rules or Rulesets

1. Edit `safe-settings/settings.yml` — modify the ruleset under `rulesets`.
2. The `safe-settings: code repos` ruleset applies to code repos.
3. The `safe-settings: non-code repos` ruleset applies to non-code repos.
4. Submit a PR and merge.
5. The daily sync applies the change automatically. For immediate
   application, trigger a manual `workflow_dispatch` run.

### Add a Repo-Specific Override

Use repo overrides sparingly. Only create one when a repo needs settings
that differ from its suborg defaults.

1. Create `safe-settings/repos/<repo-name>.yml`.
2. Set only the fields that differ from the suborg/org defaults.
3. Do NOT set peribolos-owned fields (`description`, `has_projects`,
   `default_branch`).
4. Submit a PR. CI boundary tests validate the override.

See `safe-settings/repos/complyctl.yml` for an example (complyctl requires
2 approvers instead of the org default of 1).

## Override Validator Policies

Override validators in `safe-settings/deployment-settings.yml` enforce
a security floor:

- **Approver count floor**: Suborg or repo configs cannot lower
  `required_approving_review_count` below the org default. Setting it
  higher is allowed.
- **No admin collaborators**: The `admin` permission cannot be granted
  to collaborators via safe-settings. Use peribolos team membership
  with admin role instead.

**Requesting an exception:** If a legitimate use case requires bypassing
a validator, discuss with org admins. Exceptions require modifying the
validator script in `deployment-settings.yml` via a reviewed PR.

## Code Review Assignment

GitHub Teams support automatic code review assignment, which selects a
subset of team members for each PR instead of notifying the entire team.
This works with CODEOWNERS — the team stays in CODEOWNERS but only the
selected members get pinged.

This feature is configured manually via the GitHub UI (Team Settings >
Code review assignment) because neither peribolos nor safe-settings
supports it. The GitHub REST API does not expose these settings; only
the GraphQL API v4 does (used by Terraform's `github_team_settings`
resource, which we do not use).

### Current configuration

| Team | Algorithm | Reviewers | Notify | Status |
|------|-----------|-----------|--------|--------|
| `complytime-dev` | Round robin | 2 | Only selected subset | Pending setup |

### How to configure

1. Go to the team settings: github.com/orgs/complytime/teams/`<team>`/settings
2. Under "Code review assignment", check "Enable auto assignment"
3. Set the algorithm (round robin recommended for even distribution)
4. Set the number of reviewers (e.g., 2)
5. Check "Only notify requested team members" to suppress team-wide pings
6. Optionally exclude members who should never be auto-assigned

### When to reconfigure

This is a one-time setup that rarely changes. Reconfigure when:
- Team size changes significantly (adjust reviewer count)
- A member needs permanent exclusion from review rotation
- The team wants to switch from round robin to load balance

## Local Validation

### Prerequisites

- Go (version in `go.mod`)
- `yamllint` (for YAML validation)

### Commands

```bash
# Validate all YAML (peribolos + safe-settings)
make lint

# Run all Go tests (peribolos + boundary)
make test-unit

# Validate only safe-settings YAML
make safe-settings-validate

# Full validation: format, vet, lint, tests, diff check
make sanity
```

## Applying Safe-settings Changes

safe-settings reads its config from the `.github` repo's default branch
via the GitHub API. Config changes must be **merged to main** before
safe-settings can apply them.

### Testing sequence

1. **Local validation** (before PR):
   ```bash
   make test-unit              # boundary tests
   make safe-settings-validate # YAML syntax
   ```

2. **Submit PR** — CI runs boundary tests and YAML validation.

3. **Merge PR** — config lands on main.

4. **Dry-run against a single repo** — go to Actions > "Safe Settings
   Sync" > "Run workflow":
   - Set `dry-run` to `true`
   - Set `repos` to a single repo (e.g., `complytime-demos`)
   - Review the workflow output to see what would change

5. **Apply to a single repo** — same workflow:
   - Set `dry-run` to `false`
   - Set `repos` to the same repo
   - Verify the changes in the GitHub UI

6. **Apply to all repos** — same workflow:
   - Set `dry-run` to `false`
   - Leave `repos` empty (applies to all managed repos)

### Rollback

If safe-settings applies incorrect settings:
1. `git revert` the config change and push to main
2. Trigger `workflow_dispatch` with `dry-run=false` — safe-settings
   reverts to the previous config state
3. Or fix settings manually via the GitHub UI (safe-settings will
   re-apply them on the next sync)

## Triggering Manual Sync

### Peribolos

Go to Actions > "Apply Peribolos" > "Run workflow". Set `dry-run` to
`true` for a preview, or `false` to apply.

### Safe-settings

Go to Actions > "Safe Settings Sync" > "Run workflow":
- **dry-run**: `true` to preview, `false` to apply (defaults to `true`)
- **repos**: comma-separated list of repos to target (e.g.,
  `complytime-demos,community`). Leave empty to apply to all managed
  repos.

### Automation

The Safe Settings Sync workflow runs daily at 07:00 UTC (after
peribolos apply at 05:30 UTC) to reconcile settings automatically.
Manual dispatch is available for immediate application or dry-run
previews.

## Troubleshooting

### Settings not applied after merge

1. Check the "Safe Settings Sync" workflow run in the Actions tab —
   the daily sync at 07:00 UTC should have applied the change.
2. If it hasn't run yet, trigger `workflow_dispatch` manually.
3. Look for errors in the workflow logs (credential expiry, API errors).

### Boundary test failures

Boundary tests fail when:
- A repo in a suborg file does not exist in `peribolos.yaml` — add it
  to peribolos first.
- A repo appears in multiple suborg files — each repo belongs to exactly
  one suborg.
- A safe-settings config sets `description`, `has_projects`, or
  `default_branch` — these are peribolos-owned fields.
- A suborg repo list does not match the corresponding ruleset
  `repository_name.include` — update both files together.

### safe-settings sync errors

Common causes:
- **Credential expiry**: The GitHub App private key may need rotation.
  Update the `SAFE_SETTINGS_PRIVATE_KEY` secret.
- **API rate limits**: The sync may fail if it hits GitHub API rate
  limits. Wait and re-trigger.
- **Invalid YAML**: The workflow validates YAML before applying. Check
  the yamllint output in the workflow logs.
- **safe-settings version issue**: If safe-settings behavior changes,
  check the pinned version in the workflow file.

### Known upstream workarounds

The workflow includes workarounds for two upstream safe-settings
bugs. Both are documented inline with TODO tags for removal once
fixed upstream.

#### 1. check_suite crash in full-sync mode

`handleResults` crashes because `payload.check_suite` is undefined
outside the webhook flow. The sync itself completes; only the Check
Run reporting fails. Workaround: a patched `full-sync.js` that
catches the specific TypeError and treats it as non-fatal.

- **Upstream issue**:
  [github-community-projects/safe-settings#818](https://github.com/github-community-projects/safe-settings/issues/818)
- **Upstream fix PR**:
  [github-community-projects/safe-settings#1018](https://github.com/github-community-projects/safe-settings/pull/1018)
- **Search tag**: `TODO(safe-settings-818)` in the workflow file
- **Remove when**: PR #1018 is merged and released. Update the
  pinned version and revert to `npm run full-sync`.

#### 2. Repo name mutation in concurrent processing

When processing multiple repos in parallel, safe-settings shares
the repo config object across repos via JavaScript reference. The
`name` field from the first repo (alphabetically) contaminates all
others, causing PATCH requests to try renaming every repo. The API
rejects these with HTTP 422 "name already exists". Workaround: the
workflow processes repos sequentially (one at a time) using scoped
deployment-settings for each repo.

- **Upstream issue**:
  [github-community-projects/safe-settings#901](https://github.com/github-community-projects/safe-settings/issues/901)
- **Upstream fix PR**:
  [github-community-projects/safe-settings#943](https://github.com/github-community-projects/safe-settings/pull/943)
  (merged to `main-enterprise`, not yet in a tagged release)
- **Search tag**: `TODO(safe-settings-name-mutation)` in the
  workflow file
- **Remove when**: upstream #901 is fixed in a tagged release.
  Revert to a single `node full-sync-patched.js` call without the
  per-repo loop.

## GitHub Enterprise Hierarchy

The complytime org is part of a GitHub Enterprise Cloud account. Enterprise admins can enforce policies and rulesets that layer on top of org-level settings. Understanding this hierarchy is important when managing settings with safe-settings.

### How settings layer

GitHub uses two distinct mechanisms, each with different conflict behavior:

**Rulesets** (branch protection, push rules) are always **additive**. Enterprise, org, and repo-level rulesets all apply simultaneously, and the most restrictive rule wins. There is never a conflict — just aggregation. If Enterprise requires 2 reviewers and safe-settings sets 1 at the org level, the effective result is 2. safe-settings cannot weaken Enterprise rulesets.

**Enterprise Policies** (member privileges, repo governance) operate in either **enforce** mode (org cannot change the setting) or **delegate** mode (org manages freely). When enforced, API calls that contradict them fail (HTTP 422).

### What safe-settings can and cannot affect

| Setting category | Enterprise controls? | safe-settings impact |
|-----------------|---------------------|---------------------|
| Rulesets (branch protection, push rules) | Enterprise can add its own rulesets | safe-settings org-level rulesets coexist; most restrictive wins |
| Repo feature toggles (`has_wiki`, `allow_auto_merge`, merge strategies) | No enterprise-level policy | safe-settings controls freely |
| Dependabot alerts and security fixes | Enterprise can restrict management | May fail if Enterprise locks security settings |
| Forking policy | Enterprise can enforce | Not managed by our safe-settings config |
| Repo visibility | Enterprise can restrict | Not managed by our safe-settings config |
| Org membership, teams | Enterprise can manage via SCIM/IdP | Managed by peribolos, not safe-settings |

### Key guarantees

- Enterprise admins retain full control. Enterprise-level rulesets and policies always take precedence over org-level settings.
- safe-settings cannot lock Enterprise admins out or override their policies.
- If Enterprise adds stricter rulesets in the future, they layer on top of the org-level rulesets managed by safe-settings without requiring changes to the safe-settings config.
- If safe-settings attempts to set a value that contradicts an enforced Enterprise policy, the API call fails gracefully (logged as an error, other settings still applied).

## Excluded Repos

The following repos are excluded from safe-settings management
(not listed in `deployment-settings.yml` `restrictedRepos.include`):

- `.github` — the admin repo (avoids circular dependency). Its
  ruleset ("verify") is managed manually via the GitHub UI.
- `complyscribe` — archived.

