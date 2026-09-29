<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v14** was hardened automatically. 7 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple `uses:` references in action.yml and example-workflow.yml use mutable tags instead of pinned 40-character SHA digests, making the action vulnerable to supply-chain attacks if the referenced tag is moved.

Failing references:
- action.yml: `fastly/compute-actions/setup@v14`
- example-workflow.yml: `actions/checkout@v3`
- example-workflow.yml: `fastly/compute-actions/preview@v14`

Locations:

- `action.yml:27`
- `example-workflow.yml:12`
- `example-workflow.yml:13`

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate GitHub Actions expressions (`${{ ... }}`) inside shell command strings. This allows an attacker to inject arbitrary shell commands via PR event data or action inputs before the shell ever sees the value.

Violations (sub-rule a — direct expression interpolation):
- Line 37: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}"` — `github.event.number` interpolated directly in shell
- Line 43: `fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }}` — unquoted step output and input token interpolated directly
- Line 50: `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — unquoted inputs and step outputs interpolated directly
- Line 57: `fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — step output and input token interpolated directly
- Line 63: `echo "DOMAIN=$(fastly ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...)"` — step output and input token interpolated directly
- Line 71: `echo '...${{ steps.domain.outputs.DOMAIN }}...'` — step output interpolated directly in shell

Locations:

- `action.yml:37`
- `action.yml:43`
- `action.yml:50`
- `action.yml:57`
- `action.yml:63`
- `action.yml:71`

### github-env-injection (severity: high)

Two `run:` blocks in action.yml write values derived from untrusted inputs/context directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). An attacker can inject newlines to smuggle additional key=value pairs into the output file.

Violations:
- Line 37: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` (attacker-controlled PR number field) written to GITHUB_OUTPUT without sanitization.
- Line 63: `echo "DOMAIN=$(fastly ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — `steps.service-name.outputs.SERVICE_NAME` (itself derived from `github.event.number`) written to GITHUB_OUTPUT without sanitization.

Locations:

- `action.yml:37`
- `action.yml:63`

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

**Fixes applied:** unpinned-uses, script-injection, github-env-injection, static-inline-injection

**Notes:**

Fixed all findings in action.yml and example-workflow.yml:

1. unpinned-uses: Pinned fastly/compute-actions/setup@v14 → SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786, actions/checkout@v3 → SHA a37ce9120846195fa4ece8f58b268e6043cb2f26, and fastly/compute-actions/preview@v14 → SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 (all with # tag comments for readability).

2. script-injection: Moved all ${{ github.event.number }}, ${{ inputs.fastly-api-token }}, and ${{ steps.service-name.outputs.SERVICE_NAME }} expressions out of run: blocks into env: maps. Shell commands now reference plain environment variables ($EVENT_NUMBER, $FASTLY_API_TOKEN, $SERVICE_NAME, $DOMAIN).

3. github-env-injection: The 'Set service-name' step now sanitizes the constructed service name via `printf '%s' "$raw" | tr -d '\n\r'` before writing to GITHUB_OUTPUT. The 'Set domain' step similarly sanitizes the domain value before writing to GITHUB_OUTPUT.

4. static-inline-injection: All four occurrences of ${{ inputs.fastly-api-token }} in run: blocks moved to env: maps as FASTLY_API_TOKEN.

