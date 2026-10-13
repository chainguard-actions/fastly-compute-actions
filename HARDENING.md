<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v12

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v12** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `fastly/compute-actions/setup@v12`, which is pinned to a mutable tag (`v12`) rather than an immutable 40-character commit SHA. This means the referenced action code can change without notice, enabling supply-chain attacks.

Locations:

- `preview/action.yml:28`

### script-injection (severity: high)

Multiple `run:` blocks in the composite action directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a). This allows an attacker to inject arbitrary shell commands via attacker-controlled values:

- Line 38: `${{ github.event.number }}` interpolated directly in a shell `echo` command.
- Line 44: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in a `fastly service delete` command (unquoted).
- Line 51: `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly in a `fastly compute publish` command.
- Line 57: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in a `fastly domain list` command.
- Line 64: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in a shell `echo` command.
- Line 72: `${{ steps.domain.outputs.DOMAIN }}` interpolated directly in a shell `echo` command.

All of these should be moved to `env:` variables and referenced as quoted shell variables (e.g. `"$VAR"`).

Locations:

- `preview/action.yml:38`
- `preview/action.yml:44`
- `preview/action.yml:51`
- `preview/action.yml:57`
- `preview/action.yml:64`
- `preview/action.yml:72`

### github-env-injection (severity: high)

Two `run:` blocks write untrusted values directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

- Line 38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` is attacker-controlled (PR number) and is written directly to GITHUB_OUTPUT without newline sanitization.
- Line 64: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — `steps.service-name.outputs.SERVICE_NAME` (which derives from `github.event.number`) is written to GITHUB_OUTPUT without sanitization.

An attacker could inject newlines into these values to poison subsequent steps that read from GITHUB_OUTPUT.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:64`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three findings in hardened/action/preview/action.yml:
1. unpinned-uses: Pinned `fastly/compute-actions/setup@v12` to full SHA `3b4355cb74cc7428a92dad1194bd564898372d55` with `# v12` comment.
2. script-injection: Moved all ${{ github.event.number }}, ${{ inputs.fastly-api-token }}, ${{ steps.service-name.outputs.SERVICE_NAME }}, and ${{ steps.domain.outputs.DOMAIN }} expressions out of run: shell strings into env: blocks, referencing them as quoted shell variables.
3. github-env-injection: The service-name step and domain step now capture the raw value into a variable and sanitize with `printf '%s' "$raw" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT, preventing newline injection.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in preview/action.yml that would abort the step under errexit:
1. Line 45: Added `|| true` to `raw="$(yq '.name' fastly.toml)-${EVENT_NUMBER}"` to match upstream behavior where yq was run inside echo/printf (hiding exit status).
2. Line 87: Added `|| true` to `raw="$(fastly domain list ... | jq -r '.[0].Name')"` to match upstream behavior where fastly was run inside echo/printf (hiding exit status).

