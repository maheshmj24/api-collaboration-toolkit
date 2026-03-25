# Implementation Plan: Bruno Request Prompt

**Branch**: `002-add-bruno-prompt` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-add-bruno-prompt/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add a context-aware markdown prompt that developers can run in Copilot/agent to generate a new Bruno `.bru` request file from a newly created API endpoint (typically by analyzing controller method details), plus concise usage guidance in markdown. The implementation will place prompt assets under `bruno/prompts/`, ground them on `bruno/process/PROCESS.md` and existing generated examples, and enforce repository-safe output conventions (no secrets, correct foldering, deterministic naming, PR inclusion guidance).

## Technical Context

**Language/Version**: Markdown (`.md`, `.prompt.md`) for prompt + usage docs; repository scripts remain PowerShell 5.1+ compatible  
**Primary Dependencies**: VS Code Copilot prompt execution, repository Bruno process docs, existing Bruno examples under `bruno/scaffolder/examples/`  
**Storage**: Filesystem only (new markdown prompt/documentation artifacts under source control)  
**Testing**: Manual validation by running prompt against sample endpoint/controller context and reviewing generated `.bru` artifact against process conventions  
**Target Platform**: Windows-first developer workflow in VS Code; output artifacts are platform-neutral text files  
**Project Type**: Documentation + prompt asset for developer workflow automation  
**Performance Goals**: Developer can generate PR-ready request artifact in <5 minutes (aligned to SC-002)  
**Constraints**: Must follow Bruno process and naming conventions; must avoid secret material in generated/request examples; must handle missing context and duplicates clearly  
**Scale/Scope**: One reusable prompt file, one usage guide markdown, and references to existing process docs/examples for all new endpoint additions in participating repos

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Pre-Research Gate

| #   | Constitution Principle                   | Status | Evidence                                                                                                                                                    |
| --- | ---------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| I   | Contract-Aligned Source of Truth         | PASS   | Prompt explicitly instructs deriving request details from endpoint/controller implementation and existing contract/process references, not ad hoc guessing. |
| II  | Client-Agnostic Process First            | PASS   | Feature is Bruno-specific but framed as process-consistent prompt packaging that can be mirrored for future clients.                                        |
| III | Safe, Reviewable Repository Artifacts    | PASS   | Prompt guidance requires repository-safe `.bru` output, no secrets, and reviewable deterministic structure.                                                 |
| IV  | Scaffolded Consistency Over Manual Drift | PASS   | Prompt codifies repeatable manual-add flow and references scaffolder conventions to reduce drift.                                                           |
| V   | Change Discipline and Backward Clarity   | PASS   | Plan includes markdown usage guidance and references for contributor adoption and review clarity.                                                           |
| S1  | Assets under `/bruno`                    | PASS   | Prompt artifacts planned under `bruno/prompts/`; generated requests target `/bruno/Contoso - <API>/...`.                                                    |
| S2  | Standard collection structure            | PASS   | Prompt contract enforces environments/controller/request layout from process doc.                                                                           |
| S3  | Default environments explicit            | PASS   | Prompt references LOCAL/DEV/TST expectations and no-secrets rule.                                                                                           |
| S5  | Stable naming                            | PASS   | Prompt includes naming derivation and collision guidance.                                                                                                   |
| S8  | Documentation                            | PASS   | Feature deliverables include prompt + markdown run guide + quickstart.                                                                                      |

**Pre-Research Result**: PASS

## Project Structure

### Documentation (this feature)

```text
specs/002-add-bruno-prompt/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
bruno/
├── process/
│   └── PROCESS.md
├── prompts/
│   ├── bruno-request-generator.prompt.md   # New prompt artifact (planned)
│   └── README.md                           # New "how to run" markdown (planned)
└── scaffolder/
    ├── Generate-BrunoCollection.ps1
    ├── README.md
    ├── bruno-scaffolder-config.json
    └── examples/
        └── Contoso - Event/

.github/
└── prompts/
    └── speckit.plan.prompt.md              # Existing planning prompt reference
```

**Structure Decision**: Use `bruno/prompts/` as the delivery location for developer-facing Bruno prompt assets so they live with Bruno process documentation and examples. No source runtime code changes are required; this feature is documentation/prompt workflow enablement.

## Post-Design Constitution Check

| #           | Constitution Principle                       | Status | Evidence                                                                                                          |
| ----------- | -------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------- |
| I           | Contract-Aligned Source of Truth             | PASS   | Data model and prompt contract require endpoint-derived method/route/parameters, with process/example references. |
| II          | Client-Agnostic Process First                | PASS   | Prompt pattern documented as reusable packaging approach, while maintaining Bruno as current implementation.      |
| III         | Safe, Reviewable Repository Artifacts        | PASS   | Contract and quickstart specify no secrets and PR-reviewable deterministic output.                                |
| IV          | Scaffolded Consistency Over Manual Drift     | PASS   | Prompt output rules mirror scaffolder/process structure to prevent divergent manual formats.                      |
| V           | Change Discipline and Backward Clarity       | PASS   | Quickstart and prompt README provide explicit usage and contribution expectations.                                |
| S1-S3,S5,S8 | Toolkit standards subset relevant to feature | PASS   | Artifacts remain under `/bruno`, preserve structure/naming/environments, and add documentation.                   |

**Post-Design Result**: PASS

## Complexity Tracking

No constitution violations identified. No complexity exceptions required.
