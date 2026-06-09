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

### Create a New Team or Change Team Membership

1. Edit `peribolos.yaml` — add/modify the team under the `teams` section.
2. Ensure team members are org members (CI validates this).
3. Ensure admins are listed as `maintainers`, not `members` (CI validates).
4. Submit a PR and merge.

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
4. Submit a PR. CI boundary tests validate consistency.
5. After merge, trigger `workflow_dispatch` on the "Safe Settings Sync"
   workflow to apply.

### Change Branch Protection Rules or Rulesets

1. Edit `safe-settings/settings.yml` — modify the ruleset under `rulesets`.
2. The `safe-settings: code repos` ruleset applies to code repos.
3. The `safe-settings: non-code repos` ruleset applies to non-code repos.
4. Submit a PR and merge.
5. Trigger `workflow_dispatch` to apply.

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

### Future automation

After initial validation, the workflow can be extended with:
- `push` trigger on `safe-settings/**` path changes to main
- `schedule` trigger (daily at 06:00 UTC) for drift correction

These triggers are intentionally disabled during the initial rollout to
ensure full manual control.

## Troubleshooting

### Settings not applied after merge

1. Trigger `workflow_dispatch` manually — safe-settings only runs on
   manual dispatch during initial rollout (no push/schedule triggers).
2. Check the "Safe Settings Sync" workflow run in the Actions tab.
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

## Excluded Repos

The following repos are excluded from safe-settings management:

- `.github` — the admin repo (avoids circular dependency). Its
  ruleset ("verify") is managed manually via the GitHub UI.
- `complyscribe` — archived.
- `gemara-content-service` — pending archival.

These are listed in `safe-settings/deployment-settings.yml` under
`restrictedRepos` and/or excluded from suborg files.

## Migration Notes

Existing repo-level rulesets (created manually via the GitHub UI) coexist
with the new org-level rulesets managed by safe-settings. GitHub evaluates
all active rulesets and the most restrictive rule wins.

After verifying the org-level rulesets work correctly, the old repo-level
rulesets should be deleted via the GitHub UI. The full list is documented
in comments at the top of `safe-settings/settings.yml`.
