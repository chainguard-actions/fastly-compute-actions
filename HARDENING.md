<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v13

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v13** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ }} expressions into shell commands (sub-rule a), allowing script injection. Affected lines include:
- Line 33: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number interpolated directly
- Line 38: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }}` — step output and input interpolated directly
- Line 44: `run: fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — input and step output interpolated directly
- Line 51: `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — step output and input interpolated directly
- Line 58: `run: echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...)" >> "$GITHUB_OUTPUT"` — step output and input interpolated directly
- Line 66: `run: echo '...<https://${{ steps.domain.outputs.DOMAIN }}>...' >> $GITHUB_STEP_SUMMARY` — step output interpolated directly
All these values should be passed via env: variables and then referenced as quoted shell variables.

Locations:

- `preview/action.yml:33`
- `preview/action.yml:38`
- `preview/action.yml:44`
- `preview/action.yml:51`
- `preview/action.yml:58`
- `preview/action.yml:66`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write values derived from untrusted inputs directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
1. Line 33: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR) is written directly to GITHUB_OUTPUT.
2. Line 58: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — a value derived from steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) is written to GITHUB_OUTPUT without sanitization. Both writes allow newline injection to poison the output file.

Locations:

- `preview/action.yml:33`
- `preview/action.yml:58`

### unpinned-uses (severity: high)

Multiple uses: references are pinned to mutable tags rather than full 40-character commit SHAs, making the action vulnerable to supply-chain attacks if the tag is moved:
- preview/action.yml: `uses: fastly/compute-actions/setup@v13` (tag, not a SHA)
- .github/workflows/test.yml: `uses: actions/checkout@v5` (tag, not a SHA)
- preview/example-workflow.yml: `uses: actions/checkout@v3` (tag, not a SHA)
- preview/example-workflow.yml: `uses: fastly/compute-actions/preview@v13` (tag, not a SHA)
All should be pinned to full commit SHAs with the tag as a comment.

Locations:

- `preview/action.yml:28`
- `.github/workflows/test.yml:20`
- `preview/example-workflow.yml:12`
- `preview/example-workflow.yml:13`

### missing-permissions (severity: medium)

.github/workflows/test.yml has no top-level permissions: key and no job-level permissions: key on the 'test' job. Without explicit permissions, the workflow inherits the default repository permissions (which may be read/write for contents), violating the principle of least privilege. A top-level `permissions: {}` or specific minimal permissions block should be added.

Locations:

- `.github/workflows/test.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings across three files:

1. preview/action.yml - script-injection: Moved all ${{ }} expressions from run: blocks into env: blocks and referenced them as quoted shell variables. Affected steps: service-name, delete, publish, domain list (x2), and summary.

2. preview/action.yml - github-env-injection: Both GITHUB_OUTPUT writes (service-name and domain steps) now sanitize values with `printf '%s' "$raw" | tr -d '\n\r'` before writing to prevent newline injection.

3. preview/action.yml - unpinned-uses: Pinned fastly/compute-actions/setup@v13 to full SHA 9ca64d641e165464cd4c0c988f2e549dc7d43b49.

4. .github/workflows/test.yml - missing-permissions: Added `permissions: {}` at the top level. Also pinned actions/checkout@v5 to SHA 93cb6efe18208431cddfb8368fd83d5badbf9bfd.

5. preview/example-workflow.yml - unpinned-uses: Pinned actions/checkout@v3 to SHA f43a0e5ff2bd294095638e18286ca9a3d1956744 and fastly/compute-actions/preview@v13 to SHA 9ca64d641e165464cd4c0c988f2e549dc7d43b49.

