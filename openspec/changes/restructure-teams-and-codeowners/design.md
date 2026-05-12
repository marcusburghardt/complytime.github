## Context

The complytime GitHub organization manages 12 repositories with peribolos
(declarative GitHub org management via YAML). The organization recently split
content from `complyctl` by moving the openscap-plugin to `complytime-providers`
(now called "providers"). Two providers exist today (openscap, ampel), a third
(opa) is expected. Additionally, `complytime-policies` needs dedicated ownership
for Gemara compliance content.

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
non-code repositories: `.github`, `community`, `complytime-demos`, and
`website`. Note that `complytime-dev` does NOT have write access to `.github`;
only `complytime-approvers` provides write access to that repository.

Membership: jflowers, jpower432, marcusburghardt (maintainers),
beatrizmcouto, hbraswelrh (members).

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
teams existing first (via peribolos apply).
-> Mitigation: Apply peribolos.yaml changes first (teams must exist before
CODEOWNERS references them). CODEOWNERS updates in other repos follow.

**[Provider team divergence from CODEOWNERS]** If the last-matching-pattern
rule in CODEOWNERS selects only a provider team and a future member is removed
from that team but stays in complytime-dev, they lose review access for that
provider.
-> Mitigation: This is the intended behavior. Provider teams are the authority
for provider-specific code review. The `*` fallback ensures complytime-dev
reviews shared/non-provider code.
