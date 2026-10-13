<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v13

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v13** was hardened automatically. 7 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in action.yml directly interpolate ${{ }} expressions inside shell command strings (sub-rule a). This allows an attacker to inject arbitrary shell commands via PR events or workflow_dispatch. Offending lines:
- Line 38: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number interpolated directly
- Line 43: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — steps output and inputs interpolated directly, and --service-name value is unquoted
- Line 51: `run: fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — inputs and steps outputs interpolated directly
- Line 57: `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — steps output and inputs interpolated directly
- Line 64: `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"` — steps output and inputs interpolated directly
- Line 71: `run: echo '...https://${{ steps.domain.outputs.DOMAIN }}...' >> $GITHUB_STEP_SUMMARY` — steps output interpolated directly
All ${{ ... }} values must be moved to env: variables and those variables must be double-quoted in the shell script.

Locations:

- `action.yml:38`
- `action.yml:43`
- `action.yml:51`
- `action.yml:57`
- `action.yml:64`
- `action.yml:71`

### github-env-injection (severity: high)

Two run: blocks write values derived from untrusted inputs to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
- Line 38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR) is written directly to GITHUB_OUTPUT without newline sanitization.
- Line 64: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) is written to GITHUB_OUTPUT without sanitization. An attacker could inject newlines to poison GITHUB_OUTPUT with arbitrary key=value pairs.

Locations:

- `action.yml:38`
- `action.yml:64`

### unpinned-uses (severity: high)

The action.yml composite step uses `fastly/compute-actions/setup@v13` — a mutable version tag rather than a full 40-character commit SHA. If the tag is moved (intentionally or via a supply-chain attack), the action will silently execute different code. Pin to a specific commit SHA, e.g. `fastly/compute-actions/setup@<40-char-sha> # v13`.

Locations:

- `action.yml:28`

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

Rewrote action.yml to fix all findings:
1. Pinned fastly/compute-actions/setup@v13 to full SHA 9ca64d641e165464cd4c0c988f2e549dc7d43b49
2. Moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) into env: blocks and referenced them as double-quoted shell variables
3. Sanitized both GITHUB_OUTPUT writes (SERVICE_NAME and DOMAIN) using the two-step pattern: capture raw value, then safe=$(printf '%s' "$raw" | tr -d '\n\r'), then write safe
4. Removed the duplicate/redundant fastly_api_token env entries that were already present in the original but used the wrong casing

### Iteration 2

**Fixes applied:** unpinned-uses

**Notes:**

Pinned both unpinned `uses:` references in hardened/action/example-workflow.yml:
- `actions/checkout@v3` → `actions/checkout@a37ce9120846195fa4ece8f58b268e6043cb2f26 # v3`
- `fastly/compute-actions/preview@v13` → `fastly/compute-actions/preview@9ca64d641e165464cd4c0c988f2e549dc7d43b49 # v13`

Both SHAs were resolved via lookup_action_sha and the original tags are preserved as comments for readability.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in action.yml that would abort the step under errexit if the command failed:
1. Line 45: Added '|| true' to 'raw="$(yq '.name' fastly.toml)-${EVENT_NUMBER}"' to match upstream behavior where the step carried on even if yq failed.
2. Line 87: Added '|| true' to 'raw="$(fastly service domain list ... | jq -r '.[0].Name')"' to match upstream behavior where the step carried on even if fastly/jq failed.

