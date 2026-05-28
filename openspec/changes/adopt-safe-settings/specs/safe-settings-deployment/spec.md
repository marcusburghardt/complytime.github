## ADDED Requirements

### Requirement: Dedicated GitHub App for safe-settings

A dedicated GitHub App SHALL be registered for safe-settings, separate from the
`complytime-bot` app used by peribolos. The app SHALL be named
`safe-settings-bot` (or similar distinguishable name) and installed on the
complytime organization.

The app SHALL have the following permissions:
- Repository Administration: write
- Repository Contents: read
- Repository Checks: write
- Repository Pull requests: write
- Organization Administration: read and write

The app SHALL NOT have Organization Members or any other permissions not
listed above.

#### Scenario: App installed with correct permissions

- **GIVEN** the safe-settings-bot GitHub App is registered
- **WHEN** the app is installed on the complytime org
- **THEN** the app has only the permissions listed above
- **AND** the app does not have Organization Members or Organization
  Administration write permissions

### Requirement: App credentials stored in .github repo

The safe-settings GitHub App credentials SHALL be stored in the `.github`
repository as follows:
- `SAFE_SETTINGS_APP_ID` — repository variable (not a secret, since the app
  ID is not sensitive)
- `SAFE_SETTINGS_PRIVATE_KEY` — repository secret (base64-encoded private key)

These credentials SHALL be separate from the peribolos bot credentials.
No additional secrets are required (`CLIENT_ID`, `CLIENT_SECRET`, and
`WEBHOOK_SECRET` are not needed for the GHA-only deployment model).

#### Scenario: Credentials available for workflows

- **GIVEN** the safe-settings app credentials are stored in the `.github` repo
- **WHEN** a GitHub Actions workflow references `vars.SAFE_SETTINGS_APP_ID`
  and `secrets.SAFE_SETTINGS_PRIVATE_KEY`
- **THEN** the workflow can authenticate as the safe-settings app via
  Probot-native JWT authentication

### Requirement: GitHub Actions sync workflow

A GitHub Actions workflow `safe_settings_sync.yml` SHALL be configured in
the `.github` repo to run `npm run full-sync`. The workflow SHALL initially
be triggered only by `workflow_dispatch` (manual dispatch) to allow
controlled rollout and validation. Automated triggers (`push` to main,
`schedule`) SHALL be added in a follow-up change after initial validation
is complete.

safe-settings reads its config from the admin repo's default branch via
the GitHub API. Config changes must be merged to main before the workflow
can apply them.

The workflow SHALL accept the following inputs on `workflow_dispatch`:
- `dry-run` — boolean, default `true`. When true, safe-settings runs in
  NOP mode (logs what would change without applying). Safe by default.
- `repos` — string, optional. Comma-separated list of repos to target
  (e.g., `complytime-demos,community`). When empty, applies to all
  managed repos. When provided, the workflow dynamically generates a
  scoped `deployment-settings.yml` that restricts safe-settings to only
  the specified repos.

The workflow SHALL:
- Check out the `.github` repo (admin repo with config)
- Validate YAML syntax via yamllint before running `full-sync`
- Check out `github/safe-settings` at a pinned version (TODO: replace
  with commit SHA after initial validation)
- Run `npm install` and `npm run full-sync`
- Pass environment variables: `APP_ID`, `PRIVATE_KEY`, `GH_ORG=complytime`,
  `ADMIN_REPO=.github`, `CONFIG_PATH=safe-settings`, `DEPLOYMENT_CONFIG_FILE`,
  `FULL_SYNC_NOP`
- Use a concurrency group with `cancel-in-progress: false` to prevent
  concurrent sync runs from partially applying settings
- Set `timeout-minutes` to 15 to prevent runaway execution

#### Scenario: Dry-run against a single repo

- **GIVEN** a maintainer wants to preview changes for `complytime-demos`
- **WHEN** they trigger `workflow_dispatch` with `dry-run=true` and
  `repos=complytime-demos`
- **THEN** the workflow generates a scoped deployment-settings that
  restricts safe-settings to only `complytime-demos`
- **AND** safe-settings runs in NOP mode and logs what would change
- **AND** no actual settings are applied

#### Scenario: Apply to a single repo

- **GIVEN** a maintainer has verified the dry-run output is correct
- **WHEN** they trigger `workflow_dispatch` with `dry-run=false` and
  `repos=complytime-demos`
- **THEN** safe-settings applies settings only to `complytime-demos`
- **AND** other managed repos are not affected

#### Scenario: Apply to all managed repos

- **GIVEN** config changes have been merged to main
- **WHEN** a maintainer triggers `workflow_dispatch` with `dry-run=false`
  and `repos` left empty
- **THEN** safe-settings runs `full-sync` and applies settings to all
  managed repos

#### Scenario: Sync workflow failure

- **GIVEN** the safe-settings sync workflow encounters an error (e.g.,
  credential expiry, GitHub API outage, invalid YAML)
- **WHEN** the workflow fails
- **THEN** the workflow logs include error output
- **AND** safe-settings processes each repo independently, so partial
  application is possible — this behavior is documented in MAINTAINING.md

### Requirement: Config directory in .github repo

safe-settings configuration SHALL be stored in the `.github` repo under a
`safe-settings/` directory at the repository root. The environment variable
`CONFIG_PATH` SHALL be set to `safe-settings` and `ADMIN_REPO` SHALL be set
to `.github`.

The directory structure SHALL be:
```
safe-settings/
├── settings.yml              # org-wide defaults
├── deployment-settings.yml   # runtime config
├── suborgs/                  # suborg-level settings
│   ├── code-repos.yml
│   └── non-code-repos.yml
└── repos/                    # per-repo overrides (as needed)
```

#### Scenario: Config loaded from correct location

- **GIVEN** the safe-settings config exists in the `.github` repo under
  `safe-settings/`
- **WHEN** safe-settings runs a full sync
- **THEN** it reads org-wide settings from `safe-settings/settings.yml`
  and merges them with suborg and repo level overrides

### Requirement: Deployment settings exclude admin repo

The `deployment-settings.yml` SHALL configure `restrictedRepos` to exclude
the `.github` repo, the `admin` repo (if it exists), and the
`safe-settings` repo (if it exists) from safe-settings management. The
`.github` repo's settings and rulesets remain manually managed.

#### Scenario: Admin repo excluded from management

- **GIVEN** `deployment-settings.yml` excludes `.github` from management
- **WHEN** safe-settings runs a full sync
- **THEN** it does not apply settings to the `.github` repository itself
