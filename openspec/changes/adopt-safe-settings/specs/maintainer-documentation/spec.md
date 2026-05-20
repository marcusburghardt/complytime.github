## ADDED Requirements

### Requirement: MAINTAINING.md at repository root

A `MAINTAINING.md` file SHALL be created at the repository root covering
the operational workflows for both peribolos and safe-settings. This file
serves as the single reference for maintainers managing the complytime
GitHub organization.

#### Scenario: Maintainer finds workflow documentation

- **GIVEN** a new maintainer needs to understand how org management works
- **WHEN** they read `MAINTAINING.md`
- **THEN** they find clear instructions for both peribolos and safe-settings
  workflows, including local testing, CI behavior, and troubleshooting

### Requirement: Tool boundary documented

`MAINTAINING.md` SHALL include a table or section defining which tool owns
which configuration areas:
- Peribolos: org membership, teams, team-repo permissions, repo description,
  has_projects, default_branch
- Safe-settings: repo settings (auto-merge, delete-branch-on-merge, merge
  strategies, wiki, issues), security settings, branch protection, rulesets
- Manually managed: `.github` repo's own ruleset

The documentation SHALL explain why two tools are used and what happens if
their configurations overlap.

#### Scenario: Maintainer knows where to make a change

- **GIVEN** a maintainer wants to change branch protection rules
- **WHEN** they consult the tool boundary section of `MAINTAINING.md`
- **THEN** they find that branch protection is owned by safe-settings
- **AND** they know to edit files under `safe-settings/`

### Requirement: Common workflows documented

`MAINTAINING.md` SHALL include step-by-step instructions for these workflows:
- Adding or removing an org member (peribolos)
- Creating a new team or changing team membership (peribolos)
- Adding a new repository to safe-settings management (suborg file edit)
- Changing branch protection rules or rulesets (safe-settings)
- Adding a repo-specific override (when and how to create `repos/<name>.yml`)
- Running local dry-runs for both tools
- Triggering manual sync via `workflow_dispatch`

#### Scenario: Maintainer adds a new repo to safe-settings

- **GIVEN** a new repo `new-tool` has been created in the complytime org
- **WHEN** the maintainer follows the documented workflow in `MAINTAINING.md`
- **THEN** they know to:
  1. Add the repo to `peribolos.yaml` (description, default_branch, etc.)
  2. Add the repo to the appropriate suborg file (code-repos or non-code-repos)
  3. Submit a PR and wait for CI validation
  4. Merge to trigger automatic sync

### Requirement: Override validator policies documented

`MAINTAINING.md` SHALL document what override validators are configured,
what they prevent (e.g., lowering required approver count), and how to
request an exception if a legitimate use case arises.

#### Scenario: Maintainer needs a policy exception

- **GIVEN** a repo needs a temporary exception to the minimum approver count
- **WHEN** the maintainer reads the override validator documentation
- **THEN** they find the process for requesting an exception
- **AND** they understand that exceptions require admin approval

### Requirement: Troubleshooting section

`MAINTAINING.md` SHALL include a troubleshooting section covering:
- Settings not applied after merge (check workflow run logs)
- Drift detected but not corrected (trigger manual `workflow_dispatch`)
- Boundary test failures (how to identify and fix field overlap)
- Safe-settings sync errors (common causes and remediation)

#### Scenario: Maintainer debugs a failed sync

- **GIVEN** the safe-settings sync workflow failed
- **WHEN** the maintainer consults the troubleshooting section
- **THEN** they find guidance on checking workflow logs, common error
  patterns, and how to re-trigger the sync

### Requirement: README.md links to MAINTAINING.md

The existing `README.md` SHALL be updated to include a link to
`MAINTAINING.md` for maintainer-specific documentation. `README.md` remains
focused on project overview and prerequisites.

#### Scenario: README directs maintainers to detailed docs

- **GIVEN** a user reads `README.md`
- **WHEN** they look for maintainer workflows
- **THEN** they find a link to `MAINTAINING.md`
