# Research: Bruno Scaffolder

**Phase**: 0 — Outline & Research
**Date**: 2026-03-06

## R-001: Request Body Schema Handling — Objects, Arrays, Nested `$ref`

**Decision**: Harden `Get-JsonBodyFromSchema` to correctly produce JSON templates for all common OpenAPI request body shapes.

**Rationale**: The existing implementation handles basic `$ref` resolution and `object`/`array`/`string`/`integer`/`number`/`boolean` types. However, it has known gaps:

1. **Top-level arrays**: When a request body schema is `type: array` with `items: { $ref: ... }`, the function returns a PowerShell array. PowerShell's `ConvertTo-Json` serializes single-element arrays as bare objects (not wrapped in `[]`). The existing post-processing brace-counting workaround is fragile.
2. **Nested objects**: Objects containing properties that are themselves objects with `$ref` — handled by recursion but the depth limit for `ConvertTo-Json` defaults to 2. The script passes `-Depth 10` which is sufficient.
3. **`allOf` / `oneOf` / `anyOf`**: Not currently handled. A pragmatic approach: for `allOf`, merge properties from all sub-schemas; for `oneOf`/`anyOf`, pick the first option and note the alternative in a comment placeholder.
4. **Circular `$ref`**: Not currently guarded against. Add a visited-set to prevent infinite recursion.

**Alternatives considered**:

- Using a third-party JSON schema library → rejected (violates SC-006: no external modules)
- Generating body templates as static strings → rejected (loses contract alignment)

**Implementation approach**:

- Add a `$Visited` parameter (hashset of `$ref` paths) to `Get-JsonBodyFromSchema` to break circular references
- Add `allOf` handling (merge properties), `oneOf`/`anyOf` handling (pick first)
- Replace the fragile post-processing brace-counting array fix with explicit `ConvertTo-Json` + manual array wrapping when the root schema is `type: array`
- Expand `sample-swagger.json` with endpoints exercising: top-level array body, nested object body, `$ref` chain (A→B→C), `allOf` composition

## R-002: `.bru` Filename Uniqueness (Edge Case EC-004)

**Decision**: When two endpoints in the same controller folder would produce the same `.bru` filename, disambiguate by prepending the HTTP method.

**Rationale**: The current `Get-BrunoFileName` function already incorporates method in the fallback path but NOT when using `operationId`. Two POST and PUT endpoints on the same path with the same operationId prefix could collide.

**Alternatives considered**:

- Appending a numeric suffix (`-1`, `-2`) → rejected (not descriptive)
- Always including method in filename → rejected (verbose for the common non-colliding case)

**Implementation approach**:

- After computing all filenames per controller, check for duplicates
- For duplicates only, prepend the HTTP method (e.g., `Post-UpdateShareholder.bru` vs `Put-UpdateShareholder.bru`)

## R-003: Error Handling and Verbose Mode

**Decision**: Wrap main execution in structured error handling; add `-Verbose` support via `Write-Verbose` with `[CmdletBinding()]`.

**Rationale**: The script already has `[CmdletBinding()]` and a top-level `try/catch`. Gaps:

- Invalid JSON: `ConvertFrom-Json` throws a generic error. Catch and rephrase with actionable message (FR-008).
- No paths: After parsing, if `$swaggerContent.paths` is null or has zero properties, warn and still create the skeleton (edge case EC-002).
- Output path permissions: Use `Test-Path` + a probe write before generation to fail early (edge case EC-005).
- Verbose: Replace `Write-Info` progress messages with `Write-Verbose` so they only appear with `-Verbose`. Keep summary output unconditional.

**Alternatives considered**:

- Custom `-Verbose` switch → rejected (`[CmdletBinding()]` already provides this)

## R-004: Configuration Precedence Logic

**Decision**: Clean up the config-vs-parameter precedence logic in the main execution block.

**Rationale**: The current code checks `if (-not $CompanyName -or $CompanyName -eq "Contoso")` which incorrectly treats the default value as "not provided". This means a user who explicitly passes `-CompanyName "Contoso"` gets overridden by config.

**Implementation approach**:

- Use `$PSBoundParameters.ContainsKey('CompanyName')` to detect whether the user explicitly provided the parameter
- If not explicitly provided → use config value
- If explicitly provided → command-line wins regardless of value

## R-005: Regeneration Behavior (US3)

**Decision**: On regeneration, overwrite generated files and inform the user. Do NOT delete files that are no longer in the swagger (avoid destroying manual additions).

**Rationale**: The simplest safe approach. The current code already checks `Test-Path $collectionPath` and warns. Constitution principle V (Change Discipline) requires clarity about what changed.

**Implementation approach**:

- Keep existing `Write-Warning` about directory already existing
- Add a count of files overwritten vs newly created in the summary

## R-006: Testing Strategy Scope

**Decision**: Include a verification example within this feature; defer full Pester test suite to a separate feature spec.

**Rationale**: The spec says "developer and tester friendly, not overkill." A comprehensive test suite is valuable but is a distinct engineering effort (test infrastructure, CI integration, mocking). For this feature:

- Expand `sample-swagger.json` to include endpoints with: object body, array body, nested `$ref` body, `allOf` body, no-tag endpoint, duplicate-name endpoint
- Regenerate the `Contoso - Event/` reference output
- Document a manual verification step in quickstart.md: "Run against sample-swagger, compare output to reference"

**Alternatives considered**:

- Including Pester tests in this feature → rejected (scope creep; separate feature allows focused quality gates)
- No testing at all → rejected (violates SC-002: must be verifiable)
