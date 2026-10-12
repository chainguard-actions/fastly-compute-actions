<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v14** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ }} expressions into shell commands, violating rule (a). Offending lines include:
1. `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number interpolated directly into shell.
2. `run: fastly service delete --quiet --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — step output and input interpolated directly.
3. `fastly compute publish --verbose -i --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — inputs and step outputs interpolated directly.
4. `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — expressions interpolated directly.
5. `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} ...)" >> "$GITHUB_OUTPUT"` — expressions interpolated directly.
6. `run: echo 'This pull-request has been deployed to Fastly and is available at <https://${{ steps.domain.outputs.DOMAIN }}> 🚀' >> $GITHUB_STEP_SUMMARY` — step output interpolated directly.
All values should be moved to env: vars and referenced as quoted shell variables.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:43`
- `preview/action.yml:49`
- `preview/action.yml:55`
- `preview/action.yml:63`
- `preview/action.yml:72`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write untrusted values to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
1. `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR event) is written directly to GITHUB_OUTPUT with no newline stripping.
2. `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — a value derived from steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) is written to GITHUB_OUTPUT without sanitization. An attacker could inject newlines to poison subsequent environment variables.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:63`

### unpinned-uses (severity: high)

Multiple uses: references use mutable version tags instead of pinned 40-character commit SHAs, making the action vulnerable to supply-chain attacks if the tag is moved:
- action.yml: `fastly/compute-actions/setup@v14`
- action.yml: `fastly/compute-actions/build@v14`
- action.yml: `fastly/compute-actions/deploy@v14`
- preview/action.yml: `fastly/compute-actions/setup@v14`
- preview/example-workflow.yml: `actions/checkout@v3`
- preview/example-workflow.yml: `fastly/compute-actions/preview@v14`
All references should be pinned to a full 40-character hex commit SHA (e.g. `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v3`).

Locations:

- `action.yml:44`
- `action.yml:50`
- `action.yml:56`
- `preview/action.yml:29`
- `preview/example-workflow.yml:13`
- `preview/example-workflow.yml:14`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three findings across action.yml, preview/action.yml, and preview/example-workflow.yml:

1. unpinned-uses: Pinned all 6 uses: references to full 40-char SHAs (fastly/compute-actions@a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 for v14, actions/checkout@a37ce9120846195fa4ece8f58b268e6043cb2f26 for v3).

2. script-injection: Moved all ${{ }} expressions in preview/action.yml run: blocks into env: blocks (EVENT_NUMBER, SERVICE_NAME, FASTLY_API_TOKEN, DOMAIN) and referenced them as quoted shell variables.

3. github-env-injection: Both GITHUB_OUTPUT writes now use a two-step pattern: capture raw value first, then sanitize with `printf '%s' "$raw" | tr -d '\n\r'` before writing to GITHUB_OUTPUT.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in preview/action.yml that would abort the step under errexit if the command failed:
1. Line 45: Added `|| true` to `raw="$(yq '.name' fastly.toml)-${EVENT_NUMBER}"` to preserve upstream behavior where yq ran inside echo/printf and its exit status was hidden.
2. Line 89: Added `|| true` to `raw="$(fastly service domain list ... | jq -r '.[0].Name')"` for the same reason — upstream ran this inside echo/printf so a non-zero exit didn't abort the step.

