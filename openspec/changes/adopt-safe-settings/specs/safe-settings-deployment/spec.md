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
- Organization Administration: read

The app SHALL NOT have Organization Members, Organization Administration write,
or any other permissions not listed above.

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
the `.github` repo to run `npm run full-sync`. The workflow SHALL be
triggered by:
- `push` to main branch — immediate convergence after config merges
- `schedule` daily at 06:00 UTC — drift correction (30 min after peribolos
  sync at 05:30 UTC, ensuring membership/teams are applied before repo
  settings)
- `workflow_dispatch` — manual convergence on demand

The workflow SHALL:
- Check out the `.github` repo (admin repo with config)
- Check out `github/safe-settings` at a pinned version tag
- Run `npm install` and `npm run full-sync`
- Pass environment variables: `APP_ID`, `PRIVATE_KEY`, `GH_ORG=complytime`,
  `ADMIN_REPO=.github`, `CONFIG_PATH=safe-settings`
- Use `DEPLOYMENT_CONFIG_FILE` pointing to the workspace-relative path of
  `deployment-settings.yml`

The workflow SHALL use a concurrency group to prevent concurrent sync runs.

#### Scenario: Push-triggered sync after config merge

- **GIVEN** a PR modifying safe-settings config is merged to main
- **WHEN** the push event triggers the sync workflow
- **THEN** safe-settings runs `full-sync` and applies the updated config
  to all managed repos

#### Scenario: Scheduled drift correction

- **GIVEN** a user modified repo settings via the GitHub UI
- **WHEN** the daily scheduled sync runs at 06:00 UTC
- **THEN** safe-settings detects the drift and reverts the settings to match
  the declared configuration

#### Scenario: Manual convergence via workflow_dispatch

- **GIVEN** a maintainer needs immediate convergence
- **WHEN** they trigger `workflow_dispatch` on the sync workflow
- **THEN** safe-settings runs `full-sync` and applies all settings

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
