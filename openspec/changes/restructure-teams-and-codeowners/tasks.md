## 1. Peribolos Team Definitions (this repo: .github)

- [x] 1.1 Rename `openscap-plugin-approvers` to `openscap-provider-approvers` in peribolos.yaml: update team name, description, add `privacy: closed`, expand maintainers to include `jpower432`, expand members to all complytime-dev members, change repo access from `complyctl: write` to `complytime-providers: write`
- [x] 1.2 Create `ampel-provider-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jpower432` and `marcusburghardt`, members `gvauter`, `hbraswelrh`, `sonupreetam`, `trevor-vaughan`, and `complytime-providers: write`
- [x] 1.3 Create `opa-provider-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jpower432` and `marcusburghardt`, members `fortiz-ai`, `gvauter`, `hbraswelrh`, `sonupreetam`, `trevor-vaughan`, and `complytime-providers: write`
- [x] 1.4 Create `complytime-policies-approvers` team in peribolos.yaml with `privacy: closed`, maintainers `jflowers`, `jpower432`, `marcusburghardt`, member `fortiz-ai`, and `complytime-policies: write`
- [x] 1.5 Repurpose `complytime-approvers` in peribolos.yaml: update description to "Write access to non-code repos for project stakeholders", set maintainers to `jflowers`, `jpower432`, `marcusburghardt`, set members to `beatrizmcouto`, `hbraswelrh`, set repos to `.github`, `community`, `complytime-demos`, `website` (all write)

## 2. CODEOWNERS for This Repo (.github)

- [x] 2.1 Create `.github/CODEOWNERS` with content: `* @jflowers @jpower432 @marcusburghardt @complytime/complytime-approvers`
- [x] 2.2 Delete the root `CODEOWNERS` file if it exists

## 3. CODEOWNERS for complyctl (repo: complyctl) [blocked-by: 1.x applied via peribolos]

- [x] 3.1 [P] In the `complyctl` repository, update `.github/CODEOWNERS` to a single rule: `* @complytime/complytime-dev` (remove stale `/cmd/openscap-plugin/` rule and `/cmd/complyctl/` specific rule)

## 4. CODEOWNERS for complytime-providers (repo: complytime-providers) [blocked-by: 1.x applied via peribolos]

- [x] 4.1 [P] In the `complytime-providers` repository, create `.github/CODEOWNERS` with fallback `* @complytime/complytime-dev` and per-provider rules for `/cmd/openscap-provider/`, `/cmd/ampel-provider/`, `/cmd/opa-provider/`

## 5. CODEOWNERS for complytime-policies (repo: complytime-policies) [blocked-by: 1.x applied via peribolos]

- [x] 5.1 [P] In the `complytime-policies` repository, create `.github/CODEOWNERS` with rule: `* @complytime/complytime-policies-approvers @complytime/complytime-dev`

## 6. Test Validation Updates (this repo: .github) [should complete before or alongside sections 2-5]

- [x] 6.1 Update `config_test.go` `--owners-dir` flag default from `"../"` to `"../.github"`
- [x] 6.2 Update `loadOwners` function to return separate lists for individual users and team references (split on `/` presence). Return signature: `(users []string, teams []string, err error)`
- [x] 6.3 Add validation in `TestOrgs` that team references from CODEOWNERS exist as teams in peribolos.yaml
- [x] 6.4 Maintain existing validation that individual CODEOWNERS users are org admins with minimum 3 required
- [x] 6.5 Add duplicate check for team references
- [x] 6.6 Run `go test ./...` and verify all tests pass (covers privacy:closed, sorted lists, admin-as-maintainer from existing `testTeamMembers` — no new code needed for those)

## 7. Verification [blocked-by: all prior sections]

- [x] 7.1 Run `yamllint peribolos.yaml` and verify no lint errors
- [x] 7.2 Run `go test ./config/... -v -count=1` and verify all structural validations pass (privacy:closed, sorted lists, admin-as-maintainer, team reference validation)
- [ ] 7.3 After peribolos apply, trigger `drift_detection.yml` workflow manually to confirm convergence

<!-- spec-review: passed -->
