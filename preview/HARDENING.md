<!-- markdownlint-disable -->

# Hardening Report: fastly--compute-actions--preview/v14

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **fastly--compute-actions--preview/v14** was hardened automatically. 7 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

One or more `uses:` references are pinned to mutable tags rather than full 40-character commit SHAs, making the action vulnerable to supply-chain attacks if the tag is moved.

In action.yml:
- `fastly/compute-actions/setup@v14` (line 26) — mutable tag `v14`

In example-workflow.yml:
- `actions/checkout@v3` (line 12) — mutable tag `v3`
- `fastly/compute-actions/preview@v14` (line 13) — mutable tag `v14`

All should be pinned to full SHA digests, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v3`.

Locations:

- `action.yml:26`
- `example-workflow.yml:12`
- `example-workflow.yml:13`

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions into shell command strings (sub-rule a). Before the shell executes the command, GitHub Actions performs template substitution, allowing an attacker-controlled value to inject arbitrary shell metacharacters.

Affected steps and offending expressions:

1. **Set service-name** (line 36): `${{ github.event.number }}` is interpolated directly into the shell command:
   `run: echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"`

2. **Delete service step** (line 41): `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` are interpolated directly:
   `run: fastly service delete ... --service-name ${{ steps.service-name.outputs.SERVICE_NAME }} --force --token ${{ inputs.fastly-api-token }} || true`

3. **Publish step** (line 47): `${{ inputs.fastly-api-token }}` and `${{ steps.service-name.outputs.SERVICE_NAME }}` are interpolated directly:
   `run: fastly compute publish --verbose -i --token ${{ inputs.fastly-api-token }} --service-name ${{ steps.service-name.outputs.SERVICE_NAME }}`

4. **Domain list step** (line 53): `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` are interpolated directly:
   `run: fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" --token ${{ inputs.fastly-api-token }} | jq -r '.[0].Name'`

5. **Set domain step** (line 58): `${{ steps.service-name.outputs.SERVICE_NAME }}` and `${{ inputs.fastly-api-token }}` are interpolated directly into the shell command that writes to $GITHUB_OUTPUT.

6. **Add domain to summary step** (line 65): `${{ steps.domain.outputs.DOMAIN }}` is interpolated directly:
   `run: echo 'This pull-request has been deployed ... at <https://${{ steps.domain.outputs.DOMAIN }}> 🚀' >> $GITHUB_STEP_SUMMARY`

Fix: Move all expression values into `env:` variables and reference them as quoted shell variables (e.g., `"$SERVICE_NAME"`, `"$FASTLY_API_TOKEN"`) inside the `run:` block.

Locations:

- `action.yml:36`
- `action.yml:41`
- `action.yml:47`
- `action.yml:53`
- `action.yml:58`
- `action.yml:65`

### github-env-injection (severity: high)

Two `run:` blocks write values derived from untrusted inputs to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`), enabling newline injection that could poison subsequent steps' outputs or environment.

1. **Set service-name** (line 36): Writes `${{ github.event.number }}` (attacker-controlled via PR number) directly to `$GITHUB_OUTPUT`:
   `echo "SERVICE_NAME=$(yq '.name' fastly.toml)-${{ github.event.number }}" >> "$GITHUB_OUTPUT"`
   A crafted PR title/number containing newlines could inject additional key=value pairs into `$GITHUB_OUTPUT`.

2. **Set domain** (line 58): Writes a value derived from `${{ steps.service-name.outputs.SERVICE_NAME }}` (itself derived from the untrusted PR number above) to `$GITHUB_OUTPUT`:
   `echo "DOMAIN=$(fastly service domain list ... --service-name="${{ steps.service-name.outputs.SERVICE_NAME }}" ...)" >> "$GITHUB_OUTPUT"`

Fix: Sanitize values before writing, e.g.:
```bash
safe=$(printf '%s' "$SERVICE_NAME" | tr -d '\n\r')
echo "SERVICE_NAME=$safe" >> "$GITHUB_OUTPUT"
```

Locations:

- `action.yml:36`
- `action.yml:58`

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

**Fixes applied:** unpinned-uses, script-injection, github-env-injection, static-inline-injection

**Notes:**

Fixed all findings in action.yml and example-workflow.yml:

1. Pinned fastly/compute-actions/setup@v14 to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 in action.yml.
2. Pinned actions/checkout@v3 to SHA a37ce9120846195fa4ece8f58b268e6043cb2f26 in example-workflow.yml.
3. Pinned fastly/compute-actions/preview@v14 to SHA a25cf83ef5c19ef7d86f1eebffcd8f6c02ddc786 in example-workflow.yml.
4. Moved all ${{ github.event.number }}, ${{ inputs.fastly-api-token }}, ${{ steps.service-name.outputs.SERVICE_NAME }}, and ${{ steps.domain.outputs.DOMAIN }} expressions out of run: blocks into env: maps, referencing them as quoted shell variables.
5. Added newline sanitization (printf '%s' "$raw" | tr -d '\n\r') before writing values to $GITHUB_OUTPUT in the Set service-name and Set domain steps.

