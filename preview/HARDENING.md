<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v10

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v10** was hardened automatically. 7 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple run: blocks in action.yml directly interpolate ${{ }} expressions inside shell commands (sub-rule a), allowing script injection. Affected lines:
- Line 42: `${{ github.event.number }}` interpolated directly in run: shell command.
- Line 48: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run: shell command.
- Line 57: `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` interpolated directly in run: shell command.
- Line 65: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run: shell command.
- Line 75: `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` interpolated directly in run: shell command.
- Line 83: `${{ steps.domain.outputs.DOMAIN }}` interpolated directly in run: shell command.
All of these values flow through YAML template substitution before the shell sees them, enabling command injection via crafted input values.

Locations:

- `action.yml:42`
- `action.yml:48`
- `action.yml:57`
- `action.yml:65`
- `action.yml:75`
- `action.yml:83`

### github-env-injection (severity: high)

Two run: blocks write values derived from untrusted ${{ }} expressions directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'):
- Line 42 (Set service-name step): `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"` — github.event.number is written unsanitized to GITHUB_OUTPUT.
- Line 75 (Set domain step): `echo "DOMAIN=$(fastly domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name')" >> "$GITHUB_OUTPUT"` — step output and input values are written unsanitized to GITHUB_OUTPUT. An attacker-controlled newline in these values could inject arbitrary environment variables or outputs.

Locations:

- `action.yml:42`
- `action.yml:75`

### unpinned-uses (severity: high)

The following uses: references are pinned to mutable tags or version strings rather than immutable 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:
- action.yml line 30: `uses: fastly/compute-actions/setup@v10` (tag: v10)
- example-workflow.yml line 12: `uses: actions/checkout@v3` (tag: v3)
- example-workflow.yml line 13: `uses: fastly/compute-actions/preview@v10` (tag: v10)
All should be pinned to full SHA digests, e.g. `uses: actions/checkout@<40-hex-char-sha> # v3`.

Locations:

- `action.yml:30`
- `example-workflow.yml:12`
- `example-workflow.yml:13`

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

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, static-inline-injection

**Notes:**

Fixed all findings in action.yml and example-workflow.yml:
1. Pinned fastly/compute-actions/setup@v10 to SHA ca26cccf1fa541576c6fbdf50d62feb6db6ba181 in action.yml.
2. Pinned actions/checkout@v3 to SHA a37ce9120846195fa4ece8f58b268e6043cb2f26 and fastly/compute-actions/preview@v10 to SHA ca26cccf1fa541576c6fbdf50d62feb6db6ba181 in example-workflow.yml.
3. Moved all ${{ }} expressions (github.event.number, steps.service-name.outputs.SERVICE_NAME, inputs.fastly-api-token, steps.domain.outputs.DOMAIN) out of run: blocks into env: blocks, referencing them as plain shell variables.
4. Sanitized both GITHUB_OUTPUT writes (Set service-name and Set domain steps) by capturing raw values and piping through tr -d '\n\r' before writing.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed two bare assignments that would abort the step under errexit: (1) line 45: added '|| true' to 'raw="$(yq '.name' fastly.toml)-${EVENT_NUMBER}"'; (2) line 87: added '|| true' to 'raw="$(fastly domain list --quiet --version latest --json --service-name="$SERVICE_NAME" --token "$FASTLY_API_TOKEN" | jq -r '.[0].Name')"'. Both changes preserve upstream's behavior where the command's exit status was hidden inside echo/printf arguments, allowing the step to continue and write its output even if the command fails.

