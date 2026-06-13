<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v12

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **fastly--compute-actions/v12** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ }} expressions inside shell commands (sub-rule a), allowing script injection. Affected lines:
- Line 42: `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number interpolated directly
- Line 48: `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — step output and input interpolated directly
- Line 57: `fastly compute publish --verbose -i --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — inputs interpolated directly
- Line 65: `run: fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...` — inputs/step outputs interpolated directly
- Line 75: `run: echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq ...)" >> "$GITHUB_OUTPUT"` — inputs/step outputs interpolated directly
- Line 83: `run: echo '... <https://${{ steps.domain.outputs.DOMAIN }}> ...' >> $GITHUB_STEP_SUMMARY` — step output interpolated directly

All ${{ ... }} expressions must be moved to env: variables and then the env vars must be double-quoted in the shell script.

Locations:

- `preview/action.yml:42`
- `preview/action.yml:48`
- `preview/action.yml:57`
- `preview/action.yml:65`
- `preview/action.yml:75`
- `preview/action.yml:83`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write values derived from untrusted inputs to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
- Line 42: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR) is written directly to GITHUB_OUTPUT without sanitization.
- Line 75: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...) >> "$GITHUB_OUTPUT"` — a value derived from steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) is written to GITHUB_OUTPUT without sanitization.
An attacker could inject newlines to poison GITHUB_OUTPUT with arbitrary key=value pairs.

Locations:

- `preview/action.yml:42`
- `preview/action.yml:75`

### unpinned-uses (severity: high)

The composite action preview/action.yml references `fastly/compute-actions/setup@v12` using a mutable tag (`v12`) instead of a full 40-character commit SHA. A tag can be moved to point to a different (potentially malicious) commit, enabling supply-chain attacks. The reference should be pinned to a full SHA, e.g. `fastly/compute-actions/setup@<40-char-sha> # v12`.

Locations:

- `preview/action.yml:30`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three findings in actions/hardened/fastly--compute-actions/v12/preview/action.yml:

1. unpinned-uses: Pinned `fastly/compute-actions/setup@v12` to full SHA `3b4355cb74cc7428a92dad1194bd564898372d55` with `# v12` comment.

2. script-injection: Moved all ${{ }} expressions out of run: shell strings into env: blocks. All env vars are double-quoted in shell scripts. Affected steps: service-name (EVENT_NUMBER), delete service (SERVICE_NAME, FASTLY_API_TOKEN), compute publish (SERVICE_NAME, FASTLY_API_TOKEN), domain list (SERVICE_NAME, FASTLY_API_TOKEN), set domain (SERVICE_NAME, FASTLY_API_TOKEN), add domain to summary (DOMAIN).

3. github-env-injection: Both GITHUB_OUTPUT writes now sanitize values with `printf '%s' "$raw" | tr -d '\n\r'` before writing, preventing newline injection attacks on the SERVICE_NAME and DOMAIN outputs.

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Pinned both unpinned `uses:` references in `preview/example-workflow.yml`:
- `actions/checkout@v3` → `actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744 # v3`
- `fastly/compute-actions/preview@v12` → `fastly/compute-actions/preview@3b4355cb74cc7428a92dad1194bd564898372d55 # v12`

SHAs were resolved using lookup_action_sha to ensure accuracy.

