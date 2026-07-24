## 1. Phase 1 -- Add private repos and teams to peribolos config

- [ ] 1.1 Add nunya to the `repos` section of `peribolos.yaml` with `default_branch: main`, `has_projects: true`, and `private: true`. Omit or use a generic description.
- [ ] 1.2 Add roadmap to the `repos` section of `peribolos.yaml` with `default_branch: main`, `has_projects: true`, and `private: true`. Omit or use a generic description.
- [ ] 1.3 Create the `private-repos-readers` closed team in `peribolos.yaml` with read access to nunya and roadmap. Add all 19 currently teamless members plus any other members who need read access.
- [ ] 1.4 Create the `private-repos-writers` closed team in `peribolos.yaml` with write access to nunya and roadmap (if there are members who need write but are not admins). Skip if not needed.
- [ ] 1.5 Create the `private-repos-maintainers` closed team in `peribolos.yaml` with maintain access to nunya and roadmap (if there are members who need maintain but are not admins). Skip if not needed.
- [ ] 1.6 Run `make peribolos-dryrun` to validate the config and preview changes.
- [ ] 1.7 Open Phase 1 PR, get admin review, and merge.
- [ ] 1.8 Verify peribolos has run successfully after merge (check GitHub Actions log for `peribolos-apply` workflow).
- [ ] 1.9 Verify that members of `private-repos-readers` can access nunya and roadmap through team-based access.

## 2. Phase 2 -- Change org default permission

- [ ] 2.1 Change `default_repository_permission` from `read` to `none` in `peribolos.yaml`.
- [ ] 2.2 Run `make peribolos-dryrun` to validate and preview the change.
- [ ] 2.3 Open Phase 2 PR, get admin review, and merge.
- [ ] 2.4 Verify peribolos has run successfully after merge.
- [ ] 2.5 Verify that members of `private-repos-readers` still have access to private repos.
- [ ] 2.6 Verify that an org member NOT in any private-repo team cannot access nunya or roadmap.

## 3. Retire secret team and workaround

- [ ] 3.1 Manually delete the `nunya-access` secret team from the GitHub UI (Settings > Teams).
- [ ] 3.2 Remove `--ignore-secret-teams` from `PERIBOLOS_ARGS` in `.github/workflows/peribolos-apply.yml`.
- [ ] 3.3 Remove `--ignore-secret-teams` from the peribolos command in `.github/workflows/peribolos-drift.yml`.
- [ ] 3.4 Open Phase 3 PR with the workflow changes, get admin review, and merge.
- [ ] 3.5 Verify peribolos runs successfully without the `--ignore-secret-teams` flag.

## 4. Documentation

- [ ] 4.1 Update `MAINTAINING.md` to document the procedure for granting a person access to a private repository (add to appropriate team via PR).
- [ ] 4.2 Update `MAINTAINING.md` to document the procedure for adding a new private repository to the org (add to `peribolos.yaml` repos section and to relevant team repos maps).
