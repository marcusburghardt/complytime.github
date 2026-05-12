## Why

The complytime organization has undergone structural changes: the openscap-plugin
was moved from complyctl to complytime-providers (now called "providers"), and
complytime-providers now hosts multiple providers (openscap, ampel) with a third
(opa) expected. Additionally, complytime-policies needs dedicated ownership for
Gemara content. The current peribolos team structure and CODEOWNERS files do not
reflect these changes, leaving stale references, missing ownership rules, and
no per-provider review gates.

## What Changes

- **Rename** `openscap-plugin-approvers` to `openscap-provider-approvers`, expand
  membership to all complytime-dev members, and point repo access at
  `complytime-providers` instead of `complyctl`.
- **Create** `ampel-provider-approvers` and `opa-provider-approvers` teams, each
  with all complytime-dev members as approvers (opa additionally includes
  `fortiz-ai`).
- **Create** `complytime-policies-approvers` team for Gemara content ownership in
  complytime-policies, with `fortiz-ai` as initial member.
- **Repurpose** `complytime-approvers` for write access to non-code repositories
  (.github, community, complytime-demos, website) for project stakeholders.
- **Standardize** all CODEOWNERS files to `.github/CODEOWNERS` across repositories,
  following GitHub's recommended location.
- **Create** CODEOWNERS for complytime-providers with per-provider path rules.
- **Create** CODEOWNERS for complytime-policies with combined team ownership.
- **Clean up** complyctl CODEOWNERS by removing stale openscap-plugin references
  and simplifying to a single complytime-dev fallback.
- **Move** this repo's CODEOWNERS from root to `.github/CODEOWNERS` and add
  `@complytime/complytime-approvers` as a code owner.
- **Update** `config_test.go` to handle team references in CODEOWNERS and adjust
  the file path for the new CODEOWNERS location.

## Capabilities

### New Capabilities

- `team-restructuring`: Peribolos team definitions reflecting the new
  organizational structure (rename, create, and repurpose teams).
- `codeowners-management`: CODEOWNERS file creation, cleanup, and standardization
  across complytime-providers, complytime-policies, complyctl, and .github repos.
- `test-validation`: Updated config_test.go to validate team references in
  CODEOWNERS and support the new `.github/CODEOWNERS` location.

### Modified Capabilities

(none -- no existing specs to modify)

## Impact

- **peribolos.yaml**: Team definitions restructured (1 rename, 3 creates,
  1 repurpose). Repo access mappings change for multiple teams.
- **config_test.go**: Test logic updated to split CODEOWNERS parsing into
  individual users and team references, with validation that referenced teams
  exist in peribolos.yaml.
- **CODEOWNERS (this repo)**: Moved from root to `.github/`, team reference added.
- **CODEOWNERS (complyctl)**: Stale rules removed, simplified to single fallback.
- **CODEOWNERS (complytime-providers)**: New file with per-provider ownership.
- **CODEOWNERS (complytime-policies)**: New file with combined team ownership.
- **Cross-repo**: Changes span 4 repositories (.github, complyctl,
  complytime-providers, complytime-policies). Each repo's changes are independent
  but should be coordinated.
