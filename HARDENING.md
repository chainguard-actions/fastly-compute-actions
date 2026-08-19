<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v12

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v12** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ ... }} expressions inside shell commands (sub-rule a). This allows an attacker to inject arbitrary shell commands via PR events or workflow inputs. Offending lines include:
- Line 37: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"`
- Line 42: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true`
- Line 49: `run: fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}`
- Line 56: `run: fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name'`
- Line 63: `run: echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"`
- Line 70: `run: echo 'This pull-request has been deployed ... <https://${{ steps.domain.outputs.DOMAIN }}> ...' >> $GITHUB_STEP_SUMMARY`
All ${{ ... }} values must be moved to env: variables and those variables must be double-quoted in the shell script.

Locations:

- `preview/action.yml:37`
- `preview/action.yml:42`
- `preview/action.yml:49`
- `preview/action.yml:56`
- `preview/action.yml:63`
- `preview/action.yml:70`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write values derived from untrusted inputs/context directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
- Line 37: writes `${{ github.event.number }}` (via shell interpolation) to $GITHUB_OUTPUT — a PR author controls the PR number field.
- Line 63: writes `${{ steps.service-name.outputs.SERVICE_NAME }}` (which itself was derived from github.event.number) to $GITHUB_OUTPUT.
Newline injection via these values could allow an attacker to set arbitrary output variables.

Locations:

- `preview/action.yml:37`
- `preview/action.yml:63`

### unpinned-uses (severity: high)

The following uses: references are pinned to mutable tags or version strings rather than immutable 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:
- preview/action.yml line 29: `uses: fastly/compute-actions/setup@v12` (tag: v12)
- .github/workflows/test.yml line 20: `uses: actions/checkout@v5` (tag: v5)
Each should be pinned to a full SHA, e.g. `uses: actions/checkout@<40-hex-sha> # v5`.

Locations:

- `preview/action.yml:29`
- `.github/workflows/test.yml:20`

### missing-permissions (severity: medium)

The workflow file .github/workflows/test.yml has no top-level `permissions:` key and no job-level `permissions:` key on any job. Without explicit permissions, the workflow inherits the repository's default token permissions (which may be write-all). A minimal permissions block (e.g. `permissions: contents: read`) should be added.

Locations:

- `.github/workflows/test.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed preview/action.yml: (1) Moved all ${{ }} expressions from run: blocks into env: blocks and double-quoted all env var references in shell scripts. (2) Added printf/tr sanitization for values written to $GITHUB_OUTPUT (lines 37 and 63). (3) Pinned fastly/compute-actions/setup@v12 to full SHA 3b4355cb74cc7428a92dad1194bd564898372d55. Fixed .github/workflows/test.yml: (4) Added top-level 'permissions: contents: read' block. (5) Pinned actions/checkout@v5 to full SHA 93cb6efe18208431cddfb8368fd83d5badbf9bfd.

