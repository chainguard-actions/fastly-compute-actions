<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions/v10

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions/v10** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in preview/action.yml directly interpolate ${{ }} expressions inside shell command strings (sub-rule a), allowing script injection. Offending lines include:
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github context interpolated directly in shell
- Line 44: `fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }}` — steps output and inputs interpolated directly
- Line 51: `fastly compute publish ... --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}` — inputs and steps output interpolated directly
- Line 57: `fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }}` — interpolated directly
- Line 64: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} ...)" >> "$GITHUB_OUTPUT"` — interpolated directly
- Line 71: `echo '...https://${{ steps.domain.outputs.DOMAIN }}...' >> $GITHUB_STEP_SUMMARY` — steps output interpolated directly
All ${{ ... }} expressions should be moved to env: vars and referenced as quoted shell variables.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:44`
- `preview/action.yml:51`
- `preview/action.yml:57`
- `preview/action.yml:64`
- `preview/action.yml:71`

### github-env-injection (severity: high)

Two run: blocks in preview/action.yml write values derived from untrusted inputs/github context directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
- Line 40: `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number is written directly to GITHUB_OUTPUT with no newline sanitization.
- Line 64: `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"` — steps.service-name.outputs.SERVICE_NAME (itself derived from github.event.number) is written to GITHUB_OUTPUT with no sanitization. An attacker-controlled value containing newlines could inject arbitrary key=value pairs into the output context.

Locations:

- `preview/action.yml:40`
- `preview/action.yml:64`

### unpinned-uses (severity: high)

The following uses: references are pinned to mutable tags rather than immutable 40-character SHA digests, making them vulnerable to supply-chain attacks if the tag is moved:
- preview/action.yml: `uses: fastly/compute-actions/setup@v10` (tag: v10)
- preview/example-workflow.yml: `uses: actions/checkout@v3` (tag: v3)
- preview/example-workflow.yml: `uses: fastly/compute-actions/preview@v10` (tag: v10)
All should be pinned to full SHA-1 commit hashes.

Locations:

- `preview/action.yml:29`
- `preview/example-workflow.yml:11`
- `preview/example-workflow.yml:12`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses

**Notes:**

Fixed all three findings in preview/action.yml and preview/example-workflow.yml:

1. script-injection: Moved all ${{ }} expressions from run: shell strings into env: blocks. All shell references now use quoted $VAR_NAME syntax. Affected steps: service-name (EVENT_NUMBER), delete service (FASTLY_API_TOKEN, SERVICE_NAME), compute publish (FASTLY_API_TOKEN, SERVICE_NAME), domain list (FASTLY_API_TOKEN, SERVICE_NAME), set domain (FASTLY_API_TOKEN, SERVICE_NAME), add domain to summary (DOMAIN).

2. github-env-injection: Both GITHUB_OUTPUT writes now use a two-step pattern: capture raw value into a variable, then sanitize with 'printf "%s" "$raw" | tr -d "\n\r"' before writing. This prevents newline injection into the output context.

3. unpinned-uses: Pinned all three mutable tag references to full 40-character SHA digests with tag comments preserved: fastly/compute-actions/setup@ca26cccf... # v10, actions/checkout@a37ce912... # v3, fastly/compute-actions/preview@ca26cccf... # v10.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments in preview/action.yml that would abort the step under errexit: (1) line 45: added '|| true' to the yq assignment capturing the service name; (2) line 89: added '|| true' to the fastly domain list assignment capturing the domain. Both changes match upstream behavior where these commands ran inside echo/printf arguments whose exit status hid the command's failure.

