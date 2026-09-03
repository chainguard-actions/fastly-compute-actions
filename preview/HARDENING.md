<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v14** was hardened automatically. 7 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

action.yml references fastly/compute-actions/setup@v14 using a mutable tag instead of a pinned 40-character commit SHA. A tag can be moved to point to a different (potentially malicious) commit at any time, enabling supply-chain attacks.

Locations:

- `action.yml:28`

### script-injection (severity: high)

Multiple run: blocks in action.yml directly interpolate ${{ ... }} expressions inside shell command strings (sub-rule a). GitHub Actions performs template substitution before the shell parses the string, so an attacker-controlled value can inject arbitrary shell commands.

- Line 38: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — injects github.event.number directly into shell.
- Line 43: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }}` — injects steps output and inputs directly.
- Line 50: `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — injects inputs and steps output.
- Line 55: `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — injects steps output and inputs.
- Line 62: `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} ...)" >> "$GITHUB_OUTPUT"` — injects steps output and inputs.
- Line 69: `run: echo '...https://${{ steps.domain.outputs.DOMAIN }}...' >> $GITHUB_STEP_SUMMARY` — injects steps output.

Locations:

- `action.yml:38`
- `action.yml:43`
- `action.yml:50`
- `action.yml:55`
- `action.yml:62`
- `action.yml:69`

### github-env-injection (severity: high)

Two run: blocks write values derived from untrusted inputs/github context directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r').

- Line 38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR number) is written unsanitized to GITHUB_OUTPUT. A newline in the value could inject additional output variables.
- Line 62: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — steps.service-name.outputs.SERVICE_NAME is derived from github.event.number and is written unsanitized to GITHUB_OUTPUT.

Locations:

- `action.yml:38`
- `action.yml:62`

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

Fixed all security findings in hardened/action/action.yml:
1. unpinned-uses (line 28): Pinned fastly/compute-actions/setup@v14 to full SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 with # v14 comment.
2. script-injection (lines 38, 43, 50, 55, 62, 69): Moved all ${{ github.event.number }}, ${{ steps.service-name.outputs.SERVICE_NAME }}, ${{ inputs.fastly-api-token }}, and ${{ steps.domain.outputs.DOMAIN }} expressions out of run: shell strings into env: blocks; referenced as plain env vars ($EVENT_NUMBER, $SERVICE_NAME, $FASTLY_API_TOKEN, $DOMAIN) in the shell.
3. github-env-injection (lines 38, 62): Added sanitization using printf '%s' ... | tr -d '\n\r' before writing SERVICE_NAME and DOMAIN to $GITHUB_OUTPUT.
4. static-inline-injection (lines 49, 57, 66, 76): All ${{ inputs.fastly-api-token }} occurrences in run: blocks moved to env: blocks as FASTLY_API_TOKEN.

### Iteration 2

**Fixes applied:** unpinned-uses, missing-permissions

**Notes:**

Fixed example-workflow.yml: (1) Pinned `actions/checkout@v3` to full SHA `a37ce9120846195fa4ece8f58b268e6043cb2f26 # v3` and `fastly/compute-actions/preview@v14` to full SHA `a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 # v14`. (2) Added top-level `permissions: contents: read` block — the minimal permission needed for the checkout step; no other permissions are required by this workflow.

