## ADDED Requirements

### Requirement: Installation token generation per workflow run
The apply workflow SHALL generate a fresh GitHub App installation token at the start of each run using `actions/create-github-app-token` (SHA-pinned per existing workflow conventions) with the `complytime-bot` app credentials stored in `secrets.COMPLYTIME_BOT_CLIENT_ID` and `secrets.COMPLYTIME_BOT_PRIVATE_KEY`, scoped to the `complytime` org owner.

**Depends on**: GitHub App `complytime-bot` installed with `organization_administration: write`, `members: write`, `administration: write` permissions.

#### Scenario: Token generated successfully on push to main
- **GIVEN** secrets `COMPLYTIME_BOT_CLIENT_ID` and `COMPLYTIME_BOT_PRIVATE_KEY` are configured and the `complytime-bot` app is installed on the org
- **WHEN** a push to `main` triggers the apply workflow
- **THEN** the workflow generates a valid installation token scoped to the `complytime` org owner

#### Scenario: Token generated successfully on manual dispatch
- **GIVEN** secrets `COMPLYTIME_BOT_CLIENT_ID` and `COMPLYTIME_BOT_PRIVATE_KEY` are configured and the `complytime-bot` app is installed on the org
- **WHEN** an org admin triggers the workflow manually via `workflow_dispatch`
- **THEN** the workflow generates a valid installation token scoped to the `complytime` org owner

#### Scenario: Token generation fails due to invalid credentials
- **GIVEN** `secrets.COMPLYTIME_BOT_PRIVATE_KEY` is invalid, missing, or rotated
- **WHEN** the workflow attempts to generate an installation token
- **THEN** the `create-github-app-token` step fails and the workflow run fails with a clear error message

### Requirement: Safe token file handling
The workflow SHALL write the installation token to a temporary file using shell-safe quoting (environment variable expansion via `env:` block, not inline `${{ }}` expansion in the `run:` block) to prevent injection via token content. The token file SHALL be removed in a cleanup step that runs unconditionally (`if: always()`) to prevent credential persistence after job failure.

#### Scenario: Token written safely to file
- **GIVEN** the token generation step completed successfully
- **WHEN** the token is written to the auth file
- **THEN** the write uses `echo "$TOKEN" > auth.txt` with `TOKEN` set via the step's `env:` block, not inline secret expansion

#### Scenario: Token file cleaned up after failure
- **GIVEN** Peribolos exits with a non-zero exit code
- **WHEN** the workflow proceeds to cleanup
- **THEN** the auth file is removed regardless of the Peribolos exit code

### Requirement: Peribolos uses installation token with require-self disabled
The apply workflow SHALL pass the installation token to Peribolos via `--github-token-path` and SHALL include `--require-self=false` to avoid the incompatible `GET /user` endpoint. The command SHALL include `--min-admins 2` as a compensating safety control.

#### Scenario: Peribolos authenticates with installation token
- **GIVEN** a valid installation token is written to the auth file
- **WHEN** Peribolos runs with `--require-self=false` and `--min-admins 2`
- **THEN** Peribolos exits with code 0 and the workflow logs show no authentication errors

### Requirement: Pipeline exit code propagation
The apply workflow step that executes Peribolos SHALL use `set -o pipefail` so that a non-zero exit code from Peribolos propagates through the pipeline and fails the workflow step.

#### Scenario: Peribolos failure fails the workflow
- **GIVEN** `set -o pipefail` is set in the shell step
- **WHEN** Peribolos exits with a non-zero exit code (e.g., authentication failure, API error)
- **THEN** the workflow step reports failure and the overall workflow run reports failure

#### Scenario: Peribolos success passes the workflow
- **GIVEN** `set -o pipefail` is set in the shell step
- **WHEN** Peribolos exits with exit code 0
- **THEN** the workflow step reports success

### Requirement: Explicit workflow permissions
The apply workflow SHALL declare explicit `permissions:` at the job level with the minimum required scopes (e.g., `contents: read`). The GitHub App installation token handles org-level operations; the workflow's `GITHUB_TOKEN` needs only minimal permissions.

#### Scenario: Workflow permissions are minimal
- **WHEN** the apply workflow YAML is inspected
- **THEN** explicit `permissions:` are declared at the job level with no unnecessary write scopes

## REMOVED Requirements

### Requirement: Remove unused ghproxy sidecar
The apply workflow SHALL NOT start a ghproxy background process, since Peribolos is not configured to route through it.

#### Scenario: No ghproxy process in workflow
- **WHEN** the apply workflow runs
- **THEN** no ghproxy process is started and Peribolos connects directly to the GitHub API

### Requirement: Old APP_ACCESS_TOKEN secret is no longer used
The apply workflow SHALL NOT reference `secrets.APP_ACCESS_TOKEN`. The old secret can be removed from the repository settings after migration (see design.md D1 migration plan).

#### Scenario: Workflow does not reference old secret
- **WHEN** the apply workflow YAML is inspected
- **THEN** there are no references to `APP_ACCESS_TOKEN`
