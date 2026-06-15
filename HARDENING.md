<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v13

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **fastly--compute-actions/v13** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `fastly/compute-actions/setup@v13`, which is pinned to a mutable version tag rather than an immutable 40-character commit SHA. This means the referenced action could be silently replaced with malicious code without changing the ref.

Locations:

- `preview/action.yml:29`

### script-injection (severity: high)

Multiple `run:` blocks in preview/action.yml directly interpolate GitHub Actions expressions inside shell command strings (rule a), allowing an attacker to inject arbitrary shell commands via untrusted input values:

- Line 39: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` interpolated directly into shell.
- Line 44: `fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }}` — both `steps.*.outputs.*` and `inputs.*` interpolated directly.
- Line 51: `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — same issue.
- Line 57: `fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — same issue.
- Line 64: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"` — same issue.
- Line 71: `echo '...https://${{ steps.domain.outputs.DOMAIN }}...' >> $GITHUB_STEP_SUMMARY` — `steps.*.outputs.*` interpolated directly.

Locations:

- `preview/action.yml:39`
- `preview/action.yml:44`
- `preview/action.yml:51`
- `preview/action.yml:57`
- `preview/action.yml:64`
- `preview/action.yml:71`

### github-env-injection (severity: high)

Two `run:` blocks write values derived from untrusted inputs directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

- Line 39: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` (attacker-controlled via PR) is written directly to GITHUB_OUTPUT without sanitization.
- Line 64: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — `steps.service-name.outputs.SERVICE_NAME` (derived from `github.event.number`) is written to GITHUB_OUTPUT without sanitization.

Locations:

- `preview/action.yml:39`
- `preview/action.yml:64`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three findings in preview/action.yml:
1. unpinned-uses: Pinned fastly/compute-actions/setup@v13 to commit SHA 9ca64d641e165464cd4c0c988f2e549dc7d43b49 with # v13 comment.
2. script-injection: Moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) out of run: shell strings into env: blocks; shell scripts now reference plain $VAR_NAME environment variables.
3. github-env-injection: Both GITHUB_OUTPUT writes now sanitize values using printf '%s' "$raw" | tr -d '\n\r' before writing to prevent newline injection attacks.

