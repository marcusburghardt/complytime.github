## Why

The complytime GitHub organization currently sets `default_repository_permission: read`, which grants every org member implicit read access to all repositories, including private ones (nunya, roadmap). Today all org members are from the same company, so this is acceptable. However, the organization is preparing to onboard external contributors for its open-source projects. Once external members join, they will automatically gain read access to private repositories containing sensitive information. The org-wide default must be restricted before that happens.

## What Changes

- Change `default_repository_permission` from `read` to `none` in `peribolos.yaml`. This removes implicit access to private repositories for all org members. Public repositories remain unaffected (visible to anyone on the internet).
- Add private repositories (nunya, roadmap) to the `repos` section of `peribolos.yaml` so their settings are managed as code alongside all other org repositories.
- Create closed (not secret) teams in `peribolos.yaml` to grant explicit access to private repositories at appropriate permission levels (read, write, maintain). This replaces the current manually-managed secret team (`nunya-access`) with a codified, PR-reviewed, drift-detected model.
- Remove the `--ignore-secret-teams` flag from peribolos workflows once all private repo access is managed through closed teams in the config. The flag was originally added to prevent peribolos from stripping permissions from the manually-managed `nunya-access` secret team.

## Capabilities

### New Capabilities

- `private-repo-access-control`: Defines how access to private repositories is granted, what information is exposed in the public org config, the team structure for permission levels, and the sequencing required to avoid access gaps during migration.

### Modified Capabilities

(none)

## Impact

### Files directly affected

- `peribolos.yaml` -- org default permission, new repo entries, new team definitions
- `.github/workflows/peribolos-apply.yml` -- remove `--ignore-secret-teams` flag
- `.github/workflows/peribolos-drift.yml` -- remove `--ignore-secret-teams` flag
- `MAINTAINING.md` -- document private repo access procedures

### Risks

- **Information exposure**: Adding private repos to `peribolos.yaml` (which lives in the public `.github` repo) reveals repo names, descriptions, and team memberships. The actual content of private repos remains private. See the spec for a detailed breakdown of what is newly exposed.
- **Access gap during migration**: If the org default is changed to `none` before team-based access is in place, org members will temporarily lose access to private repos. Sequencing is critical -- teams must be created and populated before the default is changed.
- **Stakeholder access disruption**: 19 org members (managers, stakeholders) currently have no team membership and rely entirely on the org-wide `default_repository_permission: read` for access. These members must be added to the appropriate private-repo team before the default is changed.
- **Secret team cleanup**: The existing `nunya-access` secret team must be retired after migration. If `--ignore-secret-teams` is removed while a secret team still exists with repo permissions, peribolos will attempt to delete it on the next run.
