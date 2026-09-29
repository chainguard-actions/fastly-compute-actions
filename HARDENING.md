<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v14** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ }} expressions into shell commands, enabling script injection. Affected lines:
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — attacker-controlled github.event.number interpolated directly.
- Line 46: `fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true` — step output and input token interpolated directly.
- Line 53: `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — input token and step output interpolated directly.
- Line 60: `fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — step output and input token interpolated directly.
- Line 68: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"` — step output and input token interpolated directly.
- Line 75: `echo '...https://${{ steps.domain.outputs.DOMAIN }}...' >> $GITHUB_STEP_SUMMARY` — step output interpolated directly.
All of these violate sub-rule (a): any ${{ ... }} expression directly inside a run: block is a script-injection risk.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:46`
- `preview/action.yml:53`
- `preview/action.yml:60`
- `preview/action.yml:68`
- `preview/action.yml:75`

### github-env-injection (severity: high)

preview/action.yml writes untrusted values derived from GitHub context directly to $GITHUB_OUTPUT without sanitization (no `printf '%s' ... | tr -d '\n\r'` step):
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number (attacker-controlled via PR number) is embedded directly in the GITHUB_OUTPUT write.
- Line 68: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — steps.service-name.outputs.SERVICE_NAME (derived from github.event.number) is written to GITHUB_OUTPUT without sanitization.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:68`

### unpinned-uses (severity: high)

Multiple action references use mutable tag refs instead of full 40-character SHA commit hashes, making them vulnerable to supply-chain attacks if the tag is moved:
- action.yml: `fastly/compute-actions/setup@v14` (line ~43), `fastly/compute-actions/build@v14` (line ~49), `fastly/compute-actions/deploy@v14` (line ~55)
- preview/action.yml: `fastly/compute-actions/setup@v14` (line ~29)
- preview/example-workflow.yml: `actions/checkout@v3` (line ~13), `fastly/compute-actions/preview@v14` (line ~14)

Locations:

- `action.yml:43`
- `action.yml:49`
- `action.yml:55`
- `preview/action.yml:29`
- `preview/example-workflow.yml:13`
- `preview/example-workflow.yml:14`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses

**Notes:**

Fixed all three findings across three files:

1. **unpinned-uses** (action.yml, preview/action.yml, preview/example-workflow.yml): Pinned all 6 action references to full 40-char SHAs. fastly/compute-actions/* → a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 # v14; actions/checkout → a37ce9120846195fa4ece8f58b268e6043cb2f26 # v3.

2. **script-injection** (preview/action.yml): Moved all ${{ }} expressions out of run: blocks into env: blocks. github.event.number → EVENT_NUMBER, inputs.fastly-api-token → FASTLY_API_TOKEN, steps.service-name.outputs.SERVICE_NAME → SERVICE_NAME, steps.domain.outputs.DOMAIN → DOMAIN. All shell commands now reference plain env vars.

3. **github-env-injection** (preview/action.yml): Sanitized values written to GITHUB_OUTPUT using `printf '%s' "$VAR" | tr -d '\n\r'` before writing. SERVICE_NAME (derived from github.event.number) and DOMAIN are both sanitized before being written to GITHUB_OUTPUT.

