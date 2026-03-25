# Implementation Plan: Bruno Scaffolder

**Branch**: `001-bruno-scaffolder` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-bruno-scaffolder/spec.md`

## Summary

Build a PowerShell 5.1+ scaffolder script that reads an OpenAPI 3.0+ JSON file and generates a complete Bruno API collection following the documented process conventions. The scaffolder already exists as a working prototype at `bruno/scaffolder/Generate-BrunoCollection.ps1` (~600 lines). This plan covers hardening the existing implementation to fully satisfy the spec — specifically improving request-body schema handling (objects, arrays, nested `$ref` chains), configuration loading, error handling, verbose mode, regeneration safety, and `.bru` filename uniqueness.

## Technical Context

**Language/Version**: PowerShell 5.1+ (cross-compatible with PowerShell 7)
**Primary Dependencies**: None — standard library only (`ConvertFrom-Json`, `ConvertTo-Json`, `Test-Path`, `Out-File`)
**Storage**: Filesystem — generates folders and UTF-8 text files
**Testing**: Pester 5.x for unit/integration tests (separate feature; this feature includes a manual verification example)
**Target Platform**: Windows (PowerShell 5.1), cross-platform optional (PowerShell 7)
**Project Type**: CLI tool (single-script scaffolder with JSON config)
**Performance Goals**: N/A — one-shot generation against a JSON file; sub-second for typical APIs (<100 endpoints)
**Constraints**: No external modules; must run on a fresh Windows machine with PowerShell 5.1
**Scale/Scope**: Typical swagger files with 5–200 endpoints, 1–20 controllers, schemas with up to 3 levels of `$ref` nesting

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| #   | Constitution Principle                   | Status  | Evidence                                                                                     |
| --- | ---------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| I   | Contract-Aligned Source of Truth         | ✅ PASS | Script reads OpenAPI JSON as single source; output traceable to spec paths, methods, schemas |
| II  | Client-Agnostic Process First            | ✅ PASS | Process defined in `PROCESS.md`; scaffolder is a Bruno adapter of that process               |
| III | Safe, Reviewable Repository Artifacts    | ✅ PASS | FR-007 mandates no secrets; placeholders and `vars:secret` sections used exclusively         |
| IV  | Scaffolded Consistency Over Manual Drift | ✅ PASS | Core purpose of this feature — scaffolder replaces manual `.bru` creation                    |
| V   | Change Discipline and Backward Clarity   | ✅ PASS | README documents usage; regeneration story (US3) covers contract evolution                   |
| S1  | Assets under `/bruno`                    | ✅ PASS | Output defaults to `./bruno`; examples live under `bruno/scaffolder/examples/`               |
| S2  | Standard collection structure            | ✅ PASS | FR-002 requires `bruno.json`, `environments/`, controller folders, `.bru` files              |
| S3  | Default environments explicit            | ✅ PASS | Config defaults: LOCAL, DEV, TST                                                             |
| S4  | OpenAPI 3.0+ input                       | ✅ PASS | FR-001 requires OpenAPI 3.0+ JSON                                                            |
| S5  | Stable naming                            | ✅ PASS | FR-003 (tags), FR-009 (folder.bru), FR-011 (operationId preference)                          |
| S6  | External config                          | ✅ PASS | FR-006 with `bruno-scaffolder-config.json`                                                   |
| S7  | Example assets sanitized                 | ✅ PASS | `examples/` contains sample-swagger and reference output                                     |
| S8  | Documentation                            | ✅ PASS | README, PROCESS.md, quickstart planned                                                       |
| W6  | Fail clearly on invalid input            | ✅ PASS | FR-008 requires clear error messages                                                         |

**Gate result**: All checks pass. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-bruno-scaffolder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
bruno/
├── process/
│   └── PROCESS.md                          # Collection structure and conventions
└── scaffolder/
    ├── Generate-BrunoCollection.ps1        # Main scaffolder script (existing, to be hardened)
    ├── bruno-scaffolder-config.json        # Organization defaults (existing)
    ├── README.md                           # Usage documentation (existing, to be updated)
    └── examples/
        ├── sample-swagger.json             # Reference OpenAPI input (existing)
        ├── README.md                       # Examples guide (existing)
        └── Contoso - Event/               # Reference generated output (existing, to be regenerated)
            ├── bruno.json
            ├── environments/
            │   ├── DEV.bru
            │   ├── LOCAL.bru
            │   └── TST.bru
            ├── Events/
            │   ├── folder.bru
            │   └── Geteventdetail.bru
            └── Shareholders/
                ├── folder.bru
                ├── Getshareholderslite.bru
                └── Updateshareholder.bru
```

**Structure Decision**: Retain the existing repository layout. The scaffolder is a single-script CLI tool under `bruno/scaffolder/`. No new directories are needed. Contracts directory is not applicable — this tool has no external API surface; its "contract" is the CLI parameter interface documented in the script help and README.

## Testing Strategy

> **Recommendation**: Include a built-in verification example within this feature (run the scaffolder against `sample-swagger.json` and compare output to the reference `Contoso - Event/` collection). A full Pester test suite with unit tests, schema edge-case coverage, and CI integration should be a **separate feature spec** to keep this feature focused on the scaffolder itself. The sample-swagger should be expanded to cover the body-type scenarios (object, array, nested `$ref`) so the reference output serves as a living correctness check.

## Complexity Tracking

No constitution violations to justify. The design uses the simplest approach: a single PowerShell script with a JSON config file, following the existing repository layout.
