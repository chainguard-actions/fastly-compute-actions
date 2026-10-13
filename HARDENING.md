<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v13

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v13** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in `preview/action.yml` directly interpolate `${{ ... }}` expressions into shell commands (rule a). This allows an attacker to inject arbitrary shell commands via attacker-controlled values:

1. `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` interpolated directly into shell.
2. `run: fastly service delete --quiet --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — both `steps.*.outputs.*` and `inputs.*` interpolated directly, and unquoted.
3. `run: fastly compute publish --verbose -i --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — direct interpolation of `inputs.*` and `steps.*.outputs.*`.
4. `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...` — direct interpolation.
5. `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...)" >> "$GITHUB_OUTPUT"` — direct interpolation.
6. `run: echo 'This pull-request has been deployed ... <https://${{ steps.domain.outputs.DOMAIN }}> ...' >> $GITHUB_STEP_SUMMARY` — direct interpolation of `steps.*.outputs.*`.

All `${{ ... }}` expressions must be moved to `env:` variables and then referenced as double-quoted shell variables.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:43`
- `preview/action.yml:50`
- `preview/action.yml:57`
- `preview/action.yml:64`
- `preview/action.yml:71`

### github-env-injection (severity: high)

Two `run:` blocks in `preview/action.yml` write untrusted values derived from `${{ ... }}` expressions directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

1. Line 38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` (attacker-controlled via PR event) is written directly to GITHUB_OUTPUT.
2. Line 64: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — `steps.service-name.outputs.SERVICE_NAME` (derived from `github.event.number`) is written to GITHUB_OUTPUT without sanitization.

An attacker can inject newlines into these values to poison the output file and set arbitrary environment variables or outputs.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:64`

### unpinned-uses (severity: high)

The following `uses:` references use mutable tags instead of full 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:

- `preview/action.yml`: `uses: fastly/compute-actions/setup@v13` (tag `v13`)
- `preview/example-workflow.yml`: `uses: fastly/compute-actions@v13` (tag `v13`) and `uses: fastly/compute-actions/preview@v13` (tag `v13`)

All `uses:` references should be pinned to a full SHA digest, e.g. `uses: fastly/compute-actions/setup@<40-char-sha> # v13`.

Locations:

- `preview/action.yml:28`
- `preview/example-workflow.yml:10`
- `preview/example-workflow.yml:11`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses

**Notes:**

Fixed all findings in preview/action.yml and preview/example-workflow.yml:

1. script-injection: Moved all ${{ }} expressions (github.event.number, inputs.fastly-api-token, steps.service-name.outputs.SERVICE_NAME, steps.domain.outputs.DOMAIN) from run: shell strings into env: blocks. All shell references now use double-quoted $VAR_NAME syntax.

2. github-env-injection: The service-name step and domain step now capture raw values first, then sanitize with `printf '%s' "$raw" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT.

3. unpinned-uses: Pinned all three uses: references to full 40-char SHAs:
   - fastly/compute-actions/setup@v13 → @9ca64d641e165464cd4c0c988f2e549dc7d43b49 # v13
   - fastly/compute-actions/preview@v13 → @9ca64d641e165464cd4c0c988f2e549dc7d43b49 # v13
   - actions/checkout@v3 → @a37ce9120846195fa4ece8f58b268e6043cb2f26 # v3

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in hardened/action/preview/action.yml that would abort the step under errexit:
1. Line 45: Added '|| true' to 'raw="$(yq '.name' fastly.toml)-${EVENT_NUMBER}"' so a non-zero exit from yq doesn't abort the step.
2. Line 89: Added '|| true' to 'raw="$(fastly service domain list ... | jq -r '.[0].Name')"' so a non-zero exit from fastly/jq doesn't abort the step.
Both changes match upstream's behavior where these commands were originally run inside echo/printf arguments, whose exit status hides the inner command's exit status.

