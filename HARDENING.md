<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v14** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple `uses:` references in action.yml and preview/action.yml are pinned to mutable version tags (@v14) rather than immutable 40-character commit SHAs. This exposes the action to supply-chain attacks if the upstream tag is moved. Affected references: `fastly/compute-actions/setup@v14`, `fastly/compute-actions/build@v14`, `fastly/compute-actions/deploy@v14` (action.yml); `fastly/compute-actions/setup@v14` (preview/action.yml).

Locations:

- `action.yml:44`
- `action.yml:50`
- `action.yml:56`
- `preview/action.yml:29`

### script-injection (severity: high)

Multiple `run:` blocks in preview/action.yml directly interpolate `${{ ... }}` expressions into shell command strings (sub-rule a), allowing an attacker to inject arbitrary shell commands. Affected expressions and lines:
- Line 40: `${{ github.event.number }}` interpolated directly into a run: command (attacker-controlled via PR number).
- Line 46: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly into a run: command.
- Line 53: `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly into a run: command.
- Line 60: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly into a run: command.
- Line 68: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly into a run: command writing to $GITHUB_OUTPUT.
- Line 75: `${{ steps.domain.outputs.DOMAIN }}` interpolated directly into a run: command.
All these values should be passed via `env:` variables and then referenced as quoted shell variables (e.g. `"$VAR"`) instead.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:46`
- `preview/action.yml:53`
- `preview/action.yml:60`
- `preview/action.yml:68`
- `preview/action.yml:75`

### github-env-injection (severity: high)

Two `run:` blocks in preview/action.yml write values derived from untrusted inputs to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` is attacker-controlled (PR number) and is written directly to GITHUB_OUTPUT without sanitization.
- Line 68: `echo "DOMAIN=$(fastly ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — the service name output (derived from the unsanitized `github.event.number`) is written to GITHUB_OUTPUT without sanitization.
An attacker could inject newlines to poison subsequent output variable reads.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:68`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three findings:

1. unpinned-uses: Pinned all four `uses:` references (fastly/compute-actions/setup, build, deploy) to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 with # v14 comment in both action.yml and preview/action.yml.

2. script-injection: In preview/action.yml, moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) out of run: shell strings into env: blocks, then referenced them as quoted shell variables ($PR_NUMBER, $FASTLY_API_TOKEN, $SERVICE_NAME, $DOMAIN).

3. github-env-injection: Both GITHUB_OUTPUT writes now sanitize values through `printf '%s' "$raw" | tr -d '\n\r'` before writing to prevent newline injection attacks. The SERVICE_NAME step sanitizes the yq+PR_NUMBER combination, and the domain step sanitizes the fastly CLI output.

### Iteration 2

**Fixes applied:** unpinned-uses, permissions

**Notes:**

Fixed preview/example-workflow.yml: (1) Pinned actions/checkout@v3 to SHA a37ce9120846195fa4ece8f58b268e6043cb2f26 and fastly/compute-actions/preview@v14 to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786, preserving original tags as comments. (2) Added top-level `permissions: {}` to deny all permissions by default, and a job-level `permissions:` block granting only `contents: read` (for checkout) and `pull-requests: write` (for the preview action to manage PR comments/deployments).

