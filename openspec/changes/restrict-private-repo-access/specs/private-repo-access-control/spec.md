## ADDED Requirements

### Requirement: Org default permission SHALL be none

The organization `default_repository_permission` in `peribolos.yaml` SHALL be set to `none`. This ensures that org membership alone does not grant access to any repository. Access to private repositories SHALL be granted exclusively through team membership or admin role.

#### Scenario: External contributor joins the org

- **WHEN** an external contributor is added to the `members` list in `peribolos.yaml`
- **THEN** the contributor SHALL have no access to private repositories (nunya, roadmap) unless explicitly added to a team that grants access to those repositories

#### Scenario: Existing org member without team membership

- **WHEN** an org member has no team membership and the default permission is `none`
- **THEN** the member SHALL still be able to view, clone, fork, and open issues on all public repositories (public repos are visible to anyone on the internet)
- **AND** the member SHALL have no access to private repositories unless added to an appropriate team

#### Scenario: Engineer with team membership on public repos

- **WHEN** an engineer is a member of a closed team (e.g., `complytime-dev`) that grants write access to public repos
- **AND** the org default permission is `none`
- **THEN** the engineer's write access to those public repos SHALL be unchanged (team grants override the base permission upward)

### Requirement: Private repos SHALL be declared in peribolos config

All private repositories in the complytime organization SHALL be listed in the `repos` section of `peribolos.yaml` with at minimum the following fields: `default_branch`, `has_projects`, and `private: true`.

#### Scenario: Private repo entry in peribolos.yaml

- **WHEN** a private repository (e.g., nunya) is added to the `repos` section of `peribolos.yaml`
- **THEN** the entry SHALL include `private: true` to ensure peribolos does not change the repo's visibility
- **AND** the repo description field MAY be omitted or set to generic text to minimize information exposure in the public config

#### Scenario: Peribolos reconciliation of private repos

- **WHEN** peribolos runs with `--fix-repos`
- **THEN** private repos listed in `peribolos.yaml` SHALL have their settings reconciled like any other repo
- **AND** peribolos SHALL NOT change the `private` flag to `false` unless `--allow-repo-publish` is explicitly set (this flag is not used in the current workflow)

### Requirement: Access to private repos SHALL be granted through closed teams

Access to private repositories SHALL be managed through closed (not secret) teams declared in `peribolos.yaml`. Teams SHALL be organized by access role, not by individual repository.

The following team structure SHALL be used:

- `private-repos-readers`: grants `read` access to all private repositories
- `private-repos-writers`: grants `write` access to all private repositories (if needed beyond the readers team)
- `private-repos-maintainers`: grants `maintain` access to all private repositories (if needed beyond admin access)

Team membership and repo mappings SHALL be declared in `peribolos.yaml` and managed through the standard PR review process.

#### Scenario: Manager needs read access to all private repos

- **WHEN** a manager or stakeholder needs to view content in private repositories
- **THEN** an admin SHALL add the person's GitHub username to the `members` list of the `private-repos-readers` team in `peribolos.yaml`
- **AND** the change SHALL go through the standard PR review process before being merged

#### Scenario: Engineer needs write access to a private repo

- **WHEN** an engineer needs to push commits to a private repository
- **THEN** an admin SHALL add the person to the `private-repos-writers` team in `peribolos.yaml`
- **AND** that person SHALL also have read access through the "highest wins" principle (write implies read)

#### Scenario: New private repo is created in the org

- **WHEN** a new private repository is created in the complytime organization
- **THEN** the repo SHALL be added to the `repos` section of `peribolos.yaml` with `private: true`
- **AND** the repo SHALL be added to the `repos` map of the appropriate private-repo teams (readers, writers, maintainers) based on who needs access

### Requirement: Migration SHALL preserve existing access

The migration from the current access model (org-wide read default + secret team) to the new model (none default + closed teams) SHALL NOT cause any member to lose access to private repositories, even temporarily.

#### Scenario: Phase 1 -- teams created before default changes

- **WHEN** Phase 1 is applied (new teams and private repo entries added to `peribolos.yaml`)
- **THEN** all current org members who have access to private repos (via the org-wide read default) SHALL be listed in the `private-repos-readers` team (or a higher-privilege team)
- **AND** peribolos SHALL create the teams and set repo permissions before Phase 2 begins

#### Scenario: Phase 2 -- default changed after teams are confirmed

- **WHEN** Phase 2 is applied (default_repository_permission changed to `none`)
- **THEN** members in the `private-repos-readers` team SHALL retain read access to private repos through their team membership
- **AND** members NOT in any private-repo team SHALL lose access to private repos (this is the intended behavior)

#### Scenario: Verification between phases

- **WHEN** Phase 1 has been merged and peribolos has run
- **THEN** an admin SHALL verify that team-based access is working correctly before proceeding to Phase 2
- **AND** verification SHALL include confirming that at least one member of `private-repos-readers` can access the private repos

### Requirement: Secret team and workaround SHALL be retired

After the migration is complete and verified, the `nunya-access` secret team SHALL be deleted from GitHub, and the `--ignore-secret-teams` flag SHALL be removed from peribolos workflows.

#### Scenario: Secret team removal after migration

- **WHEN** Phase 2 is complete and verified (closed teams are providing access, default is `none`)
- **THEN** an admin SHALL manually delete the `nunya-access` secret team from the GitHub UI
- **AND** the `--ignore-secret-teams` flag SHALL be removed from `peribolos-apply.yml` and `peribolos-drift.yml`

#### Scenario: Peribolos reconciliation after flag removal

- **WHEN** `--ignore-secret-teams` is removed from peribolos workflows
- **AND** no secret teams exist in the org
- **THEN** peribolos reconciliation SHALL behave identically to before (no secret teams to process)

#### Scenario: Unauthorized secret team creation detected

- **WHEN** `--ignore-secret-teams` has been removed
- **AND** someone manually creates a secret team in the GitHub UI
- **THEN** peribolos SHALL detect the undeclared team and attempt to delete it on the next run (standard reconciliation behavior)

### Requirement: Private repo names SHALL follow opaque naming conventions

Private repository names appear in the public `peribolos.yaml` config. To prevent information leakage through repo names, private repos SHALL use opaque or generic names that do not reveal the repository's purpose, contents, or strategic intent.

#### Scenario: Acceptable private repo names

- **WHEN** a new private repository is created in the complytime organization
- **THEN** the repository name SHALL be opaque (e.g., "nunya", "internal-tools") or generic (e.g., "private-project-1")
- **AND** the name SHALL NOT contain references to specific security vulnerabilities (e.g., "cve-2026-xxxx-response"), strategic initiatives (e.g., "acquisition-analysis"), confidential partnerships, or internal organizational matters

#### Scenario: Reviewing private repo names before adding to config

- **WHEN** a private repo is being added to `peribolos.yaml`
- **THEN** the PR reviewer SHALL verify that the repo name does not reveal sensitive information about the repo's purpose or contents

### Requirement: Private repo descriptions SHALL NOT leak sensitive information

The `description` field in `peribolos.yaml` is optional but visible in the public config. For private repositories, descriptions SHALL be omitted or set to generic text to prevent information leakage.

#### Scenario: Description omitted

- **WHEN** a private repo entry is added to `peribolos.yaml` without a `description` field
- **THEN** peribolos SHALL leave the repo's existing GitHub description unchanged
- **AND** no descriptive information about the repo SHALL appear in the public config

#### Scenario: Generic description provided

- **WHEN** a private repo entry includes a `description` field
- **THEN** the description SHALL use generic, non-revealing text (e.g., "Internal project repository")
- **AND** the description SHALL NOT contain sensitive project details, client names, security-related information, unannounced product plans, or references to specific individuals or organizations

#### Scenario: PR review catches sensitive description

- **WHEN** a PR adds or modifies a private repo description in `peribolos.yaml`
- **THEN** the PR reviewer SHALL verify the description does not reveal sensitive information before approving

### Requirement: Public config exposure SHALL be documented and bounded

The `peribolos.yaml` file resides in a public repository. Adding private repo configuration to this file exposes certain organizational metadata. The exposure SHALL be explicitly documented and bounded.

#### Scenario: Information that is exposed

- **WHEN** private repos are added to `peribolos.yaml`
- **THEN** the following information SHALL be visible in the public `.github` repository:
  - Private repository names
  - Private repository descriptions (if set)
  - That the repositories are private (`private: true`)
  - Team names and membership lists for private-repo teams
  - Permission levels granted to each team on each private repo
  - Git history of all access changes (PR history)

#### Scenario: Information that remains private

- **WHEN** private repos are added to `peribolos.yaml`
- **THEN** the following information SHALL remain inaccessible to non-authorized users:
  - Repository contents (source code, files, documents)
  - Issues, pull requests, and discussions within private repos
  - Actions workflow runs and logs within private repos
  - Branch protection rules and other repo-level settings not managed by peribolos

#### Scenario: Net security posture improvement

- **WHEN** the migration from `default_repository_permission: read` to `none` with closed teams is complete
- **THEN** the overall security posture SHALL be improved:
  - Content protection is strengthened (explicit team membership required vs. implicit org-wide read)
  - Accidental exposure risk is reduced (new org members cannot see private repos by default)
  - Access governance is added (PR-reviewed changes with git audit trail vs. manual untracked changes)
- **AND** the trade-off of exposing organizational metadata (repo names, team structure) in the public config SHALL be accepted as low-risk provided the naming and description conventions defined in this spec are followed
