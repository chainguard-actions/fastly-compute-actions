<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v14** was hardened automatically. 7 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ }}` expressions inside shell command strings (sub-rule a). This causes YAML template substitution to occur before the shell processes the string, allowing an attacker to inject shell metacharacters via PR events or workflow_dispatch. Offending lines:
- Line 38: `${{ github.event.number }}` interpolated directly in run:
- Line 44: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Line 51: `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly in run:
- Line 57: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Line 64: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run:
- Line 71: `${{ steps.domain.outputs.DOMAIN }}` interpolated directly in run:
All these values should be passed via `env:` variables and then referenced as quoted shell variables (e.g., `"$VAR"`) instead.

Locations:

- `action.yml:38`
- `action.yml:44`
- `action.yml:51`
- `action.yml:57`
- `action.yml:64`
- `action.yml:71`

### github-env-injection (severity: high)

Two `run:` blocks write values derived from untrusted inputs directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).
- Line 38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` (attacker-controlled via PR) is written to GITHUB_OUTPUT unsanitized.
- Line 64: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — `steps.service-name.outputs.SERVICE_NAME` (derived from attacker-controlled `github.event.number`) is written to GITHUB_OUTPUT unsanitized.
Newline characters in these values could allow injection of additional key=value pairs into the output file.

Locations:

- `action.yml:38`
- `action.yml:64`

### unpinned-uses (severity: high)

The following `uses:` references use mutable tags instead of pinned 40-character commit SHAs, making the action vulnerable to supply-chain attacks if the referenced tag is moved or overwritten:
- `fastly/compute-actions/setup@v14` (action.yml, line 27)
- `actions/checkout@v3` (example-workflow.yml, line 13)
- `fastly/compute-actions/preview@v14` (example-workflow.yml, line 14)
Each should be pinned to a full SHA digest, e.g. `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v3`.

Locations:

- `action.yml:27`
- `example-workflow.yml:13`
- `example-workflow.yml:14`

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

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, static-inline-injection

**Notes:**

Fixed all findings in action.yml and example-workflow.yml:

1. **unpinned-uses**: Pinned fastly/compute-actions/setup@v14 to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786, actions/checkout@v3 to SHA a37ce9120846195fa4ece8f58b268e6043cb2f26, and fastly/compute-actions/preview@v14 to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786.

2. **script-injection / static-inline-injection**: Moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) out of run: blocks into env: blocks, then referenced them as quoted shell variables ($EVENT_NUMBER, $FASTLY_API_TOKEN, $SERVICE_NAME, $DOMAIN).

3. **github-env-injection**: Added sanitization (printf '%s' "$raw" | tr -d '\n\r') before writing values to $GITHUB_OUTPUT in both the Set service-name step and the Set domain step to prevent newline injection attacks.

