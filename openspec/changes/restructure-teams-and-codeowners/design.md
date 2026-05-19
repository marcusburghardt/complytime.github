## Context

The complytime GitHub organization manages 12 repositories with peribolos
(declarative GitHub org management via YAML). The organization recently split
content from `complyctl` by moving the openscap-plugin to `complytime-providers`
(the concept formerly called "plugins" is now called "providers"). Two providers exist today (openscap, ampel), a third
(opa) is expected. Additionally, `complytime-policies` needs dedicated ownership
for Gemara compliance content.

This change assumes the `fix-peribolos-implementation` change has been applied.
That change wires the `testTeamMembers()` validation function into `TestOrgs()`
and fixes admin/member role placement in existing teams. The new teams defined
here follow the corrected role assignment pattern established by that change.

Current state:
- `openscap-plugin-approvers` team still points at `complyctl` with stale naming
- No per-provider teams exist for ampel or opa
- No CODEOWNERS in complytime-providers or complytime-policies
- complyctl CODEOWNERS references `/cmd/openscap-plugin/` which no longer exists
- CODEOWNERS file locations are inconsistent (root vs `.github/`)
- `config_test.go` only validates individual users in CODEOWNERS, not team refs

## Goals / Non-Goals

**Goals:**
- Reflect the provider split in peribolos team structure
- Enable per-provider code review gates via CODEOWNERS
- Establish Gemara content ownership in complytime-policies
- Repurpose complytime-approvers for non-code repo stakeholder access
- Standardize CODEOWNERS location to `.github/CODEOWNERS` across all repos
- Update config_test.go to validate team references in CODEOWNERS
- Document why `privacy: closed` is required for all teams

**Non-Goals:**
- Reducing member duplication across teams via YAML anchors or nested teams
  (explored and deferred; explicit lists kept for clarity)
- Changing complytime-dev membership or its broad write-access model
- Modifying repository settings beyond team access and CODEOWNERS
- Automating CODEOWNERS generation from peribolos config

## Decisions

### 1. Team naming convention: `*-provider-approvers`

Rename `openscap-plugin-approvers` to `openscap-provider-approvers` and follow
the same pattern for new teams: `ampel-provider-approvers`,
`opa-provider-approvers`. This reflects the terminology shift from "plugins" to
"providers."

**Alternative considered**: Generic `*-approvers` naming. Rejected because the
`-provider-` infix makes it clear these teams scope to the complytime-providers
repository specifically.

### 2. All complytime-dev members in every provider team

Every provider team includes all complytime-dev members (maintainers as team
maintainers, members as team members). Provider-specific contributors are added
on top (e.g., `fortiz-ai` for opa). This ensures the core dev team can always
review any provider code.

**Alternative considered**: Nested teams where provider teams inherit
complytime-dev membership. Rejected because GitHub CODEOWNERS only resolves
direct team members, not parent-team members. Child teams inherit repo
permissions but not CODEOWNERS review eligibility.

### 3. CODEOWNERS standardized to `.github/CODEOWNERS`

GitHub searches for CODEOWNERS in `.github/`, root, then `docs/`, using the
first found. The `.github/` location is recommended by GitHub documentation as
the most secure option, particularly for protecting the CODEOWNERS file itself.

**Reference**: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

### 4. `privacy: closed` for all teams (requirement, not preference)

All teams MUST use `privacy: closed`. GitHub CODEOWNERS requires teams to be
"visible" to be referenced. In GitHub's team privacy model, `closed` means
visible to all organization members, while `secret` teams cannot be referenced
in CODEOWNERS files.

**References**:
- CODEOWNERS visibility requirement: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Team privacy values: https://docs.github.com/en/rest/teams/teams#create-a-team

### 5. complytime-approvers repurposed for non-code repos

Rather than deleting `complytime-approvers` and creating a new team, repurpose
it with updated membership and repo access. This team grants write access to
non-code repositories: `community`, `complytime-demos`, and `website`.

The `.github` repository is explicitly excluded from this team's repo access.
Write access to the org management repo would provide no practical benefit
(contributors can fork to create PRs) while unnecessarily expanding the attack
surface. Only org admins retain write access to `.github` through their admin
role.

Membership: jflowers, jpower432, marcusburghardt (maintainers),
beatrizmcouto, hbraswelrh (members).

### 5a. Peribolos `--required-admins` for admin removal protection

The `apply_peribolos.yml` workflow includes `--required-admins` flags for each
current org admin (jflowers, jpower432, marcusburghardt). This causes peribolos
to fail if any of these admins are removed from the `admins:` list in
peribolos.yaml, providing defense-in-depth against admin removal even if a
malicious change passes code review.

### 6. config_test.go validation strategy

Split CODEOWNERS owner parsing into individual users and team references
(detected by presence of `/` in the owner string). Individual users are
validated as org admins (existing behavior). Team references are validated
against peribolos.yaml team definitions.

**Alternative considered**: Skipping team references entirely in validation.
Rejected because this would allow typos or references to non-existent teams.

### 7. complytime-providers CODEOWNERS uses provider teams only (not dev + provider)

Each provider path references only its provider team, not `complytime-dev`:
```
/cmd/openscap-provider/ @complytime/openscap-provider-approvers
```

Since all complytime-dev members are already in each provider team, adding
`@complytime/complytime-dev` would be redundant. The `*` fallback to
`@complytime/complytime-dev` covers shared code and any paths not matching a
provider-specific rule.

## Risks / Trade-offs

**[Member list duplication]** Provider teams duplicate complytime-dev members
explicitly. Adding/removing a dev requires updating multiple teams.
-> Mitigation: Accepted trade-off. The teams are defined in a single file
(peribolos.yaml) and validated by tests. YAML anchors or nested teams were
explored and deferred for simplicity.

**[Cross-repo coordination]** Changes span 4 repositories. CODEOWNERS changes
in complyctl, complytime-providers, and complytime-policies depend on the
teams existing first (via peribolos apply). If CODEOWNERS references a
non-existent team, GitHub silently ignores the reference — PRs merge without
the intended review gate, which is a silent security degradation.
-> Mitigation: Apply peribolos.yaml changes first (teams must exist before
CODEOWNERS references them). CODEOWNERS updates in other repos follow. After
peribolos apply, trigger the `drift_detection.yml` workflow manually to confirm
convergence between peribolos.yaml and the actual GitHub org state.

**[Team rename partial failure]** Renaming `openscap-plugin-approvers` to
`openscap-provider-approvers` is a destructive, non-atomic operation — peribolos
deletes the old team and creates the new one. If the apply fails midway, the
old team may be deleted before the new team is created, temporarily leaving
affected users without team-based write access.
-> Mitigation: Risk accepted. The impact is limited to the openscap-plugin team
rename only. Users retain org-level read access and complytime-dev write access
during any transient state. The drift detection workflow catches divergence.

**[Provider team divergence from CODEOWNERS]** If the last-matching-pattern
rule in CODEOWNERS selects only a provider team and a future member is removed
from that team but stays in complytime-dev, they lose review access for that
provider.
-> Mitigation: This is the intended behavior. Provider teams are the authority
for provider-specific code review. The `*` fallback ensures complytime-dev
reviews shared/non-provider code.
