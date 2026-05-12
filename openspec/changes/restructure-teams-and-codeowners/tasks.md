## 1. Peribolos Team Definitions (this repo)

- [ ] 1.1 Rename `openscap-plugin-approvers` to `openscap-provider-approvers` in peribolos.yaml: update team name, description, expand maintainers to include `jpower432`, expand members to all complytime-dev members, change repo access from `complyctl: write` to `complytime-providers: write`
- [ ] 1.2 Create `ampel-provider-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jpower432` and `marcusburghardt`, members `gvauter`, `hbraswelrh`, `sonupreetam`, `trevor-vaughan`, and `complytime-providers: write`
- [ ] 1.3 Create `opa-provider-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jpower432` and `marcusburghardt`, members `fortiz-ai`, `gvauter`, `hbraswelrh`, `sonupreetam`, `trevor-vaughan`, and `complytime-providers: write`
- [ ] 1.4 Create `complytime-policies-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jflowers`, `jpower432`, `marcusburghardt`, member `fortiz-ai`, and `complytime-policies: write`
- [ ] 1.5 Repurpose `complytime-approvers` in peribolos.yaml: update description to "Write access to non-code repos for project stakeholders", set maintainers to `jflowers`, `jpower432`, `marcusburghardt`, set members to `beatrizmcouto`, `hbraswelrh`, set repos to `.github`, `community`, `complytime-demos`, `website` (all write)

## 2. CODEOWNERS for This Repo (.github)

- [ ] 2.1 Create `.github/CODEOWNERS` with content: `* @jflowers @jpower432 @marcusburghardt @complytime/complytime-approvers`
- [ ] 2.2 Delete the root `CODEOWNERS` file

## 3. CODEOWNERS for complyctl

- [ ] 3.1 Update `complyctl/.github/CODEOWNERS` to a single rule: `* @complytime/complytime-dev` (remove stale `/cmd/openscap-plugin/` rule and `/cmd/complyctl/` specific rule)

## 4. CODEOWNERS for complytime-providers

- [ ] 4.1 Create `complytime-providers/.github/CODEOWNERS` with fallback `* @complytime/complytime-dev` and per-provider rules for `/cmd/openscap-provider/`, `/cmd/ampel-provider/`, `/cmd/opa-provider/`

## 5. CODEOWNERS for complytime-policies

- [ ] 5.1 Create `complytime-policies/.github/CODEOWNERS` with rule: `* @complytime/complytime-policies-approvers @complytime/complytime-dev`

## 6. Test Validation Updates (this repo)

- [ ] 6.1 Update `config_test.go` `--owners-dir` flag default from `"../"` to `"../.github"`
- [ ] 6.2 Update `loadOwners` function to return separate lists for individual users and team references (split on `/` presence)
- [ ] 6.3 Add validation in `TestOrgs` that team references from CODEOWNERS exist as teams in peribolos.yaml
- [ ] 6.4 Maintain existing validation that individual CODEOWNERS users are org admins with minimum 3 required
- [ ] 6.5 Add duplicate check for team references
- [ ] 6.6 Run `go test ./...` and verify all tests pass

## 7. Verification

- [ ] 7.1 Run `yamllint peribolos.yaml` and verify no lint errors
- [ ] 7.2 Verify all team member and maintainer lists are alphabetically sorted
- [ ] 7.3 Verify all teams have `privacy: closed`
