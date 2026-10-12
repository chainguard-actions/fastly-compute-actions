<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v14** was hardened automatically. 7 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `fastly/compute-actions/setup@v14`, which is pinned to a mutable version tag (`@v14`) rather than an immutable 40-character commit SHA. This means the referenced action can be silently changed by the upstream repository, enabling a supply-chain attack.

Locations:

- `action.yml:28`

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ }}` expressions inside shell command strings (sub-rule a), allowing an attacker to inject arbitrary shell commands via attacker-controlled values:

- Line 37 (Set service-name): `${{ github.event.number }}` interpolated directly in `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"`
- Line 43 (Delete service): `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true`
- Line 50 (Deploy): `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly in `run: fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}`
- Line 57 (Domain list): `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}`
- Line 64 (Set domain): same expressions interpolated in `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"`
- Line 71 (Add domain to summary): `${{ steps.domain.outputs.DOMAIN }}` interpolated directly in `run: echo '... <https://${{ steps.domain.outputs.DOMAIN }}> ...' >> $GITHUB_STEP_SUMMARY`

All these values should be passed via `env:` variables and referenced as quoted shell variables (e.g., `"$VAR"`) instead.

Locations:

- `action.yml:37`
- `action.yml:43`
- `action.yml:50`
- `action.yml:57`
- `action.yml:64`
- `action.yml:71`

### github-env-injection (severity: high)

Two `run:` blocks write values derived from untrusted inputs or GitHub context directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

- Line 37 (Set service-name): `${{ github.event.number }}` (attacker-controllable via PR number) is embedded in the value written to `$GITHUB_OUTPUT` — `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"`. A newline in this value could inject additional key=value pairs into the output file.
- Line 64 (Set domain): `${{ steps.service-name.outputs.SERVICE_NAME }}` (derived from the above unsanitized value) is written to `$GITHUB_OUTPUT` — `echo "DOMAIN=$(... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"`. Again no sanitization is applied before the write.

Fix: apply `safe=$(printf '%s' "$VALUE" | tr -d '\n\r')` before each write to `$GITHUB_OUTPUT`.

Locations:

- `action.yml:37`
- `action.yml:64`

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
1. unpinned-uses: Pinned `fastly/compute-actions/setup@v14` to full commit SHA `a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786` with `# v14` comment.
2. script-injection: Moved all `${{ }}` expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) to `env:` blocks and referenced them as quoted shell variables.
3. github-env-injection: Both GITHUB_OUTPUT writes now capture raw value first, then sanitize with `printf '%s' "$raw" | tr -d '\n\r'` before writing.
4. static-inline-injection: All `${{ inputs.fastly-api-token }}` occurrences moved to env: blocks as FASTLY_API_TOKEN.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in action.yml that would abort the step under bash errexit: (1) line 45: added '|| true' to 'raw="$(yq '.name' fastly.toml)-${PR_NUMBER}"'; (2) line 87: added '|| true' to 'raw="$(fastly service domain list ... | jq -r '.[0].Name')"'. Both changes preserve upstream's behavior where the commands originally ran inside echo/printf arguments, hiding their exit status.

