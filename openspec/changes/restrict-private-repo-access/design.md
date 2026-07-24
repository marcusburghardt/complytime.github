## Context

The complytime GitHub organization manages its structure (members, teams, repos, permissions) as code through `peribolos.yaml` in the public `.github` repository. Peribolos reconciles this config against GitHub on every push to main and on a daily schedule.

Currently, `default_repository_permission` is set to `read`, granting all 32 org members implicit read access to every repository, including private ones (nunya, roadmap). Private repo access is supplemented by a manually-managed secret team (`nunya-access`) that was created to survive peribolos reconciliation (commit `d603ac5`, May 29, 2026). The `--ignore-secret-teams` flag was added to both `peribolos-apply.yml` and `peribolos-drift.yml` to prevent peribolos from deleting this team.

The organization plans to onboard external open-source contributors. Under the current default, any new org member would immediately gain read access to all private repositories containing sensitive information.

### Current member landscape

- 4 admins (always have full access regardless of settings)
- 9 members in teams with explicit repo access (engineers)
- 19 members with zero team membership (managers, stakeholders) who rely entirely on the org-wide `read` default

### Constraints

- `peribolos.yaml` lives in the public `.github` repository -- its contents are visible to anyone
- Peribolos runs with `--fix-org`, `--fix-teams`, `--fix-team-members`, `--fix-repos`, `--fix-team-repos` -- it reconciles all aspects of org state
- GitHub's base permission is a floor: team grants override it upward, never downward

## Goals / Non-Goals

**Goals:**

- Prevent future external org members from accessing private repositories
- Codify private repository access in `peribolos.yaml` so changes are PR-reviewed and drift-detected
- Maintain uninterrupted access for current members during the migration
- Document what org-structure information becomes publicly visible and what remains private

**Non-Goals:**

- Auditing which of the 19 teamless members actually need private repo access (deferred to a follow-up)
- Changing team structure for public repos (engineers' access is already correct)
- Managing access for repos outside the complytime org

## Decisions

### Decision 1: Change `default_repository_permission` to `none`

**Choice**: Set the org-wide base permission to `none`.

**Alternatives considered**:
- Keep `read` and manage access per-repo via collaborators: Does not scale; no code review, no drift detection, requires per-repo manual management.
- Set to `read` and use repo-level overrides: GitHub does not support lowering access below the org default on a per-repo basis. The base permission is a floor, not a ceiling.

**Rationale**: `none` is the only value that prevents org members from implicitly accessing private repos. For public repos, the change is transparent -- public repos are visible to anyone on the internet regardless of base permission. Engineers already have explicit team-based access to all repos they work on.

### Decision 2: Bring private repos into peribolos-managed config

**Choice**: Add nunya and roadmap to the `repos` section of `peribolos.yaml` and create closed teams for access.

**Alternatives considered**:
- Keep using manually-managed secret teams: Works for 1-2 repos but does not scale. No PR review on access changes, no drift detection, no git audit trail. Requires the `--ignore-secret-teams` workaround.
- Use direct collaborators (per-user, per-repo): Even less scalable; no team abstraction, no code review.

**Rationale**: Codifying access in `peribolos.yaml` provides the same governance model used for all other org resources: changes go through PR review, peribolos detects drift, and git history records who changed what and when.

### Decision 3: Use role-based teams spanning all private repos

**Choice**: Create teams organized by access pattern (role), not by repo.

Structure:
- `private-repos-readers`: read access to all private repos (managers, stakeholders)
- `private-repos-writers`: write access to all private repos (contributing engineers)
- `private-repos-maintainers`: maintain access to all private repos (project leads)

A single team can grant different permission levels per repo in its `repos` map, but all members of a team get the same permissions. Using the "highest wins" principle, a member in both `private-repos-readers` and `private-repos-writers` gets write access.

**Alternatives considered**:
- One team per repo-permission combination (nunya-read, nunya-write, roadmap-read, etc.): Combinatorial explosion -- 2 repos x 3 levels = 6 teams; scales to N x M.
- One team per repo: Still requires multiple teams per repo if different members need different permission levels.

**Rationale**: In practice, access patterns tend to be role-based (observers read everything, engineers write to everything they work on). This keeps the team count at O(permission-levels) rather than O(repos x permission-levels). If a specific member needs an asymmetric pattern (e.g., write on nunya but read on roadmap), they can be placed in `private-repos-readers` and a separate team can grant write on nunya only.

### Decision 4: Sequencing -- teams first, then default change

**Choice**: Apply changes in two phases to avoid any access gap.

Phase 1: Add private repo entries and teams to `peribolos.yaml`, merge and let peribolos create the teams.
Phase 2: Change `default_repository_permission` to `none` in a separate PR.

**Rationale**: If the default is changed before teams exist, all 19 teamless members immediately lose access to private repos. Creating teams first ensures access is in place before the floor is removed.

### Decision 5: Remove `--ignore-secret-teams` after migration

**Choice**: Remove the flag from both `peribolos-apply.yml` and `peribolos-drift.yml` after the `nunya-access` secret team is manually deleted from GitHub.

**Rationale**: The flag was a workaround for managing a secret team outside of peribolos. Once all access is codified in closed teams, the flag is no longer needed. Removing it restores full reconciliation coverage -- peribolos will detect and flag any manually-created teams, which is the desired behavior.

## Risks / Trade-offs

### Threat model: information exposure in the public config

Adding private repos to `peribolos.yaml` (which lives in the public `.github` repository) exposes organizational metadata. This section analyzes the threat model for each category of exposed information.

#### What is exposed vs. what remains private

| Information | Currently visible? | After this change | Risk level |
|---|---|---|---|
| Private repo names (nunya, roadmap) | No | Yes | Low (opaque names reveal nothing about content) |
| Private repo descriptions | No | Yes (if set) | **Variable** (depends entirely on description text) |
| That these repos are private | No | Yes (`private: true`) | Minimal (confirms existence, attacker still can't access) |
| Who has access to private repos | No | Yes (team memberships) | Low-Medium (see social engineering analysis below) |
| What permission level each person has | No | Yes (team repos mapping) | Low (read vs. write is minor signal) |
| Repo contents (code, issues, PRs) | No | **Still no** | N/A (content protection is strengthened) |
| Git history of access changes | No | Yes (PR history) | Low (audit trail is a feature, not a risk) |

#### Threat: repo descriptions leak sensitive context

The `description` field is the primary vector for accidental information leakage. Repo names like "nunya" and "roadmap" are opaque, but a description like "Security vulnerability tracking and incident response playbooks" would reveal the repo's purpose to anyone browsing the public config.

**Mitigation**: Repo descriptions in `peribolos.yaml` SHALL be omitted or set to generic, non-revealing text (e.g., "Internal project repository"). The spec includes a formal requirement for this.

#### Threat: repo names leak strategic intent

Current repo names (nunya, roadmap) are innocuous. However, future private repos with names like "cve-2026-xxxx-response" or "acquisition-target-analysis" would leak strategic information through the name alone.

**Mitigation**: Private repository names SHALL be opaque or generic. The spec includes a naming convention requirement to prevent information leakage through repo names.

#### Threat: team membership enables social engineering

Exposing which specific users have access to private repos could help an attacker target phishing or account compromise attempts at those individuals.

**Analysis**: This risk is **incremental, not new**. The full org membership list (all 32 usernames) is already public in `peribolos.yaml`. An attacker already knows every org member. The new information is which subset has private repo access specifically. Since all 32 members currently have implicit read access to private repos via `default_repository_permission: read`, the current targeting surface is actually larger (any org member is a valid target). After this change, only team members are valid targets -- a smaller, more controlled set.

**Mitigation**: No additional mitigation needed beyond existing GitHub account security practices (2FA, SSO).

#### Net security posture comparison

The current model hides the access structure but weakly protects the content. The proposed model exposes the structure but strongly protects the content:

| Aspect | Current model (default: read) | Proposed model (default: none) |
|---|---|---|
| Content protection | Weak (any org member sees everything; one org invite = full access) | Strong (explicit team membership via reviewed PR required) |
| Structure visibility | Hidden (secret team, no public config) | Exposed (repo names, team memberships in public config) |
| Access change governance | None (manual, no review, no audit trail) | Full (PR-reviewed, drift-detected, git history) |
| Social engineering surface | All 32 org members are valid targets | Only team members are valid targets (smaller set) |
| Accidental exposure risk | High (new org member immediately sees private repos) | Low (requires explicit team addition via PR) |

**Conclusion**: The proposed model is strictly better from a sensitive information protection standpoint. The trade-off is exposing organizational metadata (repo names, team structure) in the public config, which is low-risk provided naming and description conventions are followed.

### Access gap during migration

**Risk**: If the default permission is changed before teams are created and populated, members lose access to private repos.

**Mitigation**: Strict two-phase sequencing. Teams are created and verified in Phase 1. The default permission is changed only in Phase 2, after Phase 1 is confirmed working. Each phase is a separate PR.

### Secret team cleanup ordering

**Risk**: If `--ignore-secret-teams` is removed before the `nunya-access` secret team is deleted from GitHub, peribolos will see an undeclared team and attempt to delete it on the next run.

**Mitigation**: Delete the `nunya-access` secret team manually from GitHub only after confirming that closed-team access is working correctly. Remove `--ignore-secret-teams` from the workflows in the same PR or immediately after.

### Stakeholder access over-provisioning

**Risk**: All 19 currently teamless members are added to `private-repos-readers` to preserve existing access, but not all of them may need it.

**Mitigation**: This is an intentional temporary measure. A follow-up review of the `private-repos-readers` membership should be planned to remove unnecessary access. The PR-based model makes this easy -- just submit a PR removing members from the team.

## Open Questions

1. Should private repo descriptions in `peribolos.yaml` be omitted or set to generic text to minimize exposure?
2. Are there members among the 19 stakeholders who are known to NOT need private repo access and can be excluded from the initial `private-repos-readers` team?
3. Is there a timeline for onboarding external contributors that drives urgency for this change?
4. Are the `private-repos-maintainers` actually needed, or are admins sufficient for the maintain-level responsibilities on private repos?
