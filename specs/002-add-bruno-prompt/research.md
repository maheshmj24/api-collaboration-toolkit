# Research: Bruno Request Prompt

**Phase**: 0 - Outline & Research  
**Date**: 2026-03-18

## R-001: Prompt Artifact Location and Delivery Format

**Decision**: Place the reusable prompt under `bruno/prompts/` as `bruno-request-generator.prompt.md`, and include a companion markdown usage guide in the same directory.

**Rationale**: The prompt serves Bruno-specific collaboration workflow, and colocating it with `bruno/process/PROCESS.md` and scaffolder examples maximizes discoverability for contributors working on API artifacts. It also keeps feature assets aligned with constitution standards that root collaboration artifacts under `bruno`.

**Alternatives considered**:

- Place prompt only in `.github/prompts/`: rejected because that area is currently oriented to Speckit workflow prompts rather than Bruno contributor workflow guidance.
- Put usage instructions in root README only: rejected because developers need localized, task-specific guidance near Bruno process assets.

## R-002: Canonical Bruno Request Structure Rules for Prompt Output

**Decision**: Prompt output must follow process-defined conventions: collection folder `Contoso - <API NAME>`, controller-level folders, required environment coverage (LOCAL/DEV/TST), and one `.bru` file per endpoint operation.

**Rationale**: These conventions are explicitly documented in `bruno/process/PROCESS.md` and reflected in scaffolded examples. Aligning prompt-generated artifacts to those rules prevents manual drift and avoids review churn.

**Alternatives considered**:

- Allow free-form folder/file placement as long as request is valid Bruno syntax: rejected because it would conflict with process standards and make PRs inconsistent.
- Require scaffolder rerun for each endpoint addition: rejected because this feature specifically addresses incremental endpoint additions where developers need focused per-endpoint generation.

## R-003: Controller Method to `.bru` Mapping Policy

**Decision**: Prompt instructions should derive `.bru` content from endpoint/controller method details using deterministic mapping rules:

- Controller/class route -> controller folder placement
- HTTP verb + route attributes -> Bruno request section and URL
- Method signature/query/header/path bindings -> corresponding Bruno parameter blocks
- Request DTO/body schema -> `body:json` placeholder template for POST/PUT/PATCH

**Rationale**: This preserves contract alignment and mirrors how the scaffolder maps API operations from OpenAPI to `.bru` artifacts while still supporting code-first endpoint workflows.

**Alternatives considered**:

- Ask developers to manually fill a template without code analysis: rejected due to higher risk of omissions and reduced time savings.
- Depend on operationId/tag metadata only: rejected because code-first controller methods may not expose those metadata directly in source.

## R-004: Missing Context and Duplicate Artifact Handling

**Decision**: The prompt must explicitly require clarification and halt generation when endpoint context is insufficient, and must avoid silent duplicates by requiring an explicit update-vs-create decision when a matching `.bru` already exists.

**Rationale**: This directly satisfies FR-007 and FR-008 and avoids accidental inconsistencies in collaboration artifacts.

**Alternatives considered**:

- Best-effort generation with guessed fields when context is missing: rejected because it hides uncertainty and creates unreliable artifacts.
- Always overwrite same-name file: rejected because it can destroy intentional manual refinements.

## R-005: "How to Run" Documentation Scope

**Decision**: Provide a concise markdown run guide that includes exact prompt copy instructions, minimal required user inputs, in-repo context expectations, and a short validation checklist.

**Rationale**: Developers should not need external toolkit docs to execute this flow in their own repositories after initial scaffolder bootstrap. A focused in-repo guide lowers adoption friction and avoids context-transfer overhead.

**Alternatives considered**:

- Document run instructions only inside prompt body: rejected because contributors often need a quick reference document independent of prompt internals.

## R-006: Single-Collection Enforcement Strategy

**Decision**: Enforce one API project to one Bruno collection by discovering collection folders under `bruno/` and halting generation when zero or multiple candidates are found.

**Rationale**: The process guidance standardizes one collection per API project. Explicit enforcement prevents accidental generation into the wrong collection and avoids silent convention drift.

**Alternatives considered**:

- Allow implicit selection of the first discovered collection: rejected because it is non-deterministic for larger repositories.
- Require `collectionName` as mandatory input: rejected because discovery should be automatic in standard compliant repos; `collectionName` remains optional confirmation.

## R-007: Context Budgeting for Large Collections

**Decision**: Use bounded context acquisition in prompt flow: structure-first scan, then sample at most 3 `.bru` files and at most 400 lines total before requesting focused clarification.

**Rationale**: Large API collections can exceed practical model context windows. A bounded strategy preserves quality while avoiding full-folder reads and token blowups.

**Alternatives considered**:

- Read all sibling `.bru` files for maximum context: rejected due to poor scalability and high token cost.
- Zero-sample mode always: rejected because at least minimal style inference is needed to stay convention-aligned.

## R-008: Sample Harness Naming Scope

**Decision**: Rename project/folder/csproj assets to prompt-neutral names (`dotnet-api-sample`, `DotnetApiSample`) while keeping README content explicit about prompt testing scenarios.

**Rationale**: Project assets should remain reusable for both scaffolder and prompt validation, while user-facing docs can still communicate prompt-specific test workflows.

**Alternatives considered**:

- Keep prompt-specific project names: rejected because it implies narrow scope and discourages scaffolder-only validation use cases.
- Remove prompt terminology everywhere including docs: rejected because it obscures actual prompt test intent.

## Findings Update (2026-03-18)

- Scaffolder output is contract-driven; if Swagger includes PUT, scaffolder will generate PUT even when a local sample controller does not.
- Prompt flow should be source-driven for incremental endpoint additions and should not require developers to manually provide verb/route/parameters/body.
- External process-reference attachment is not practical for consumer repos that only contain generated `bruno/` assets.
- Fixed localhost port assumptions are brittle in sample docs; runtime access guidance should rely on terminal-reported base URL.

## Clarifications Resolved

- Repository path for prompt assets: `bruno/prompts/` (resolved)
- Expected prompt output destination: existing Bruno collection/controller folder path under `bruno/` (resolved)
- Required context for running prompt: in-repository Bruno folder structure and existing request artifacts after initial scaffolder/manual setup (resolved)
- Validation mechanism: manual checklist against process conventions and PR requirements (resolved)
