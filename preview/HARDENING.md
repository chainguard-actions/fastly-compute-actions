<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v12

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v12** was hardened automatically. 7 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a), enabling script injection. Affected lines:
- Line 40: `${{ github.event.number }}` interpolated directly in run: shell command
- Line 46: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Lines 52-53: `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly in run:
- Line 58: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Line 66: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Line 73: `${{ steps.domain.outputs.DOMAIN }}` interpolated directly in run:
All of these values are attacker-controllable (PR number, action inputs, step outputs) and must be passed via env: variables and then double-quoted in the shell script instead of being interpolated directly.

Locations:

- `action.yml:40`
- `action.yml:46`
- `action.yml:52`
- `action.yml:58`
- `action.yml:66`
- `action.yml:73`

### github-env-injection (severity: high)

Two `run:` steps write values derived from untrusted inputs/context directly to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — writes github.event.number (attacker-controlled PR number) unsanitized to GITHUB_OUTPUT.
- Line 66: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — writes a value derived from steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) unsanitized to GITHUB_OUTPUT.
A newline injected into these values could allow an attacker to set arbitrary environment variables or outputs.

Locations:

- `action.yml:40`
- `action.yml:66`

### unpinned-uses (severity: high)

The composite action step uses `fastly/compute-actions/setup@v12` — a mutable version tag rather than a pinned 40-character commit SHA. This means the action could be silently updated to a different (potentially malicious) version without any change to this file. It should be pinned to a full SHA, e.g. `fastly/compute-actions/setup@<40-char-sha> # v12`.

Locations:

- `action.yml:29`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.fastly-api-token }}" appears directly in run: block of step ""; move to env: map

Locations:

- `action.yml:49`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.fastly-api-token }}" appears directly in run: block of step ""; move to env: map

Locations:

- `action.yml:57`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.fastly-api-token }}" appears directly in run: block of step ""; move to env: map

Locations:

- `action.yml:66`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.fastly-api-token }}" appears directly in run: block of step "Set domain"; move to env: map

Locations:

- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, static-inline-injection, github-env-injection

**Notes:**

Fixed all findings in action.yml:
1. Pinned fastly/compute-actions/setup@v12 to full SHA 3b4355cb74cc7428a92dad1194bd564898372d55 (# v12 comment preserved).
2. Moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) out of run: shell strings into env: blocks; referenced as double-quoted $VAR_NAME in shell.
3. Sanitized both GITHUB_OUTPUT writes: service-name step and Set domain step now capture raw values then pipe through 'printf "%s" "$raw" | tr -d "\n\r"' before writing, preventing newline injection.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments that would abort the step under errexit:
1. action.yml line 45: Added `|| true` to `raw="$(yq '.name' fastly.toml)-${PR_NUMBER}"` so a non-zero yq exit doesn't abort the step.
2. action.yml line 87: Added `|| true` to `raw="$(fastly domain list ... | jq -r '.[0].Name')"` so a non-zero fastly/jq exit doesn't abort the step.
Both match upstream behavior where these commands were run inside echo/printf arguments whose own exit status hid the command's exit status.

