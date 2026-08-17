<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v14** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple `uses:` references are pinned to mutable version tags instead of immutable 40-character commit SHAs, making the action vulnerable to supply-chain attacks if the tag is moved. Failing references: `fastly/compute-actions/setup@v14`, `fastly/compute-actions/build@v14`, `fastly/compute-actions/deploy@v14` (action.yml); `fastly/compute-actions/setup@v14` (preview/action.yml); `actions/checkout@v7` (.github/workflows/test.yml).

Locations:

- `action.yml:44`
- `action.yml:50`
- `action.yml:57`
- `preview/action.yml:29`
- `.github/workflows/test.yml:21`

### script-injection (severity: high)

Multiple `run:` blocks in preview/action.yml directly interpolate `${{ ... }}` expressions into shell commands, enabling script injection. Violating lines include: (a) `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}"` — github context interpolated directly; (a) `fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} ... --token ${{ inputs.fastly-api-token }}` — step output and input interpolated directly; (a) `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — inputs interpolated directly; (a) `fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — inputs and step outputs interpolated directly; (a) `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} ...)"` — interpolated directly into GITHUB_OUTPUT write; (a) `echo '... https://${{ steps.domain.outputs.DOMAIN }} ...'` — step output interpolated directly into GITHUB_STEP_SUMMARY.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:45`
- `preview/action.yml:53`
- `preview/action.yml:62`
- `preview/action.yml:75`
- `preview/action.yml:83`

### github-env-injection (severity: high)

Two `run:` steps in preview/action.yml write untrusted expression values directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). (1) Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — `github.event.number` is attacker-controlled via a PR and is interpolated directly. (2) Line 75: `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — the step output (itself derived from attacker-influenced data) is written without sanitization.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:75`

### missing-permissions (severity: medium)

The workflow file `.github/workflows/test.yml` has no top-level `permissions:` key, and the single `test` job also has no `permissions:` key. Without explicit permissions, the workflow inherits the repository's default token permissions, which may be overly broad (e.g., write access to contents). A minimal `permissions:` block (e.g., `contents: read`) should be added.

Locations:

- `.github/workflows/test.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection, missing-permissions

**Notes:**

Fixed all four findings:

1. **unpinned-uses**: Pinned all mutable tag references to full 40-char commit SHAs with tag comments preserved:
   - fastly/compute-actions/{setup,build,deploy}@v14 → @a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 # v14 (action.yml and preview/action.yml)
   - actions/checkout@v7 → @3d3c42e5aac5ba805825da76410c181273ba90b1 # v7 (.github/workflows/test.yml)

2. **script-injection**: Moved all ${{ }} expressions out of run: shell strings into env: blocks in preview/action.yml. github.event.number → EVENT_NUMBER, inputs.fastly-api-token → FASTLY_API_TOKEN, steps.service-name.outputs.SERVICE_NAME → SERVICE_NAME, steps.domain.outputs.DOMAIN → DOMAIN. All shell references use double-quoted $VAR form.

3. **github-env-injection**: Both GITHUB_OUTPUT writes now sanitize values with `printf '%s' "$var" | tr -d '\n\r'` before writing, preventing newline injection.

4. **missing-permissions**: Added top-level `permissions: contents: read` to .github/workflows/test.yml.

