<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v10

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **fastly--compute-actions/v10** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ ... }} expressions into shell commands, violating rule (a). This allows an attacker to inject arbitrary shell commands via controlled inputs or GitHub event data.

1. Line ~38: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — injects github.event.number directly into shell.
2. Line ~43: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — injects steps output and inputs directly.
3. Line ~50: `run: fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — injects inputs and steps output.
4. Line ~57: `run: fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — injects steps output and inputs.
5. Line ~63: `run: echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"` — injects steps output and inputs.
6. Line ~72: `run: echo 'This pull-request has been deployed to Fastly and is available at <https://${{ steps.domain.outputs.DOMAIN }}> 🚀' >> $GITHUB_STEP_SUMMARY` — injects steps output.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:43`
- `preview/action.yml:50`
- `preview/action.yml:57`
- `preview/action.yml:63`
- `preview/action.yml:72`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write values derived from untrusted ${{ ... }} expressions directly to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

1. Line ~38: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR) is written unsanitized to GITHUB_OUTPUT.
2. Line ~63: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — steps.service-name.outputs.SERVICE_NAME (derived from github.event.number) is written unsanitized to GITHUB_OUTPUT.

Locations:

- `preview/action.yml:38`
- `preview/action.yml:63`

### unpinned-uses (severity: high)

The following uses: references are pinned to mutable tags/versions rather than immutable 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:

- preview/action.yml: `uses: fastly/compute-actions/setup@v10` (tag @v10)
- preview/example-workflow.yml: `uses: actions/checkout@v3` (tag @v3)
- preview/example-workflow.yml: `uses: fastly/compute-actions/preview@v10` (tag @v10)

All should be pinned to full SHA digests, e.g. `uses: actions/checkout@<40-char-sha> # v3`.

Locations:

- `preview/action.yml:28`
- `preview/example-workflow.yml:11`
- `preview/example-workflow.yml:12`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses

**Notes:**

Fixed all three findings in preview/action.yml and preview/example-workflow.yml:

1. script-injection: Moved all ${{ }} expressions from run: blocks into env: blocks. All 6 locations fixed — github.event.number, steps.service-name.outputs.SERVICE_NAME, inputs.fastly-api-token, and steps.domain.outputs.DOMAIN are now referenced as plain shell environment variables.

2. github-env-injection: Added sanitization (printf '%s' ... | tr -d '\n\r') before writing to $GITHUB_OUTPUT in both the service-name step and the domain step.

3. unpinned-uses: Pinned all three mutable tag references to full 40-character commit SHAs:
   - fastly/compute-actions/setup@v10 → @ca26cccf1fa541576c6fbdf50d62feb6db6ba181 # v10
   - actions/checkout@v3 → @f43a0e5ff2bd294095638e18286ca9a3d1956744 # v3
   - fastly/compute-actions/preview@v10 → @ca26cccf1fa541576c6fbdf50d62feb6db6ba181 # v10

