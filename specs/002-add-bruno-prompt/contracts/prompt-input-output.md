# Contract: Bruno Request Generator Prompt

## Purpose

Define the user-facing interface contract for the Bruno request generation prompt workflow.

## Invocation Contract

The prompt workflow accepts a single endpoint context and produces at most one new `.bru` request artifact.

### Required Inputs

| Input               | Type   | Description                                         |
| ------------------- | ------ | --------------------------------------------------- |
| `endpointReference` | string | Controller method or endpoint identifier to analyze |

### Optional Inputs

| Input            | Type   | Description                                                    |
| ---------------- | ------ | -------------------------------------------------------------- |
| `collectionName` | string | Optional collection name confirmation                          |
| `controllerName` | string | Optional controller override when source analysis is ambiguous |

`apiName` is not part of the prompt contract.

## Output Contract

### Success Output

| Output              | Type   | Description                                              |
| ------------------- | ------ | -------------------------------------------------------- |
| `generatedFilePath` | string | Relative path to generated `.bru` file                   |
| `generationSummary` | string | Short summary of source-derived method/route/params/body |
| `validationResults` | array  | Checks run against process conventions                   |
| `nextAction`        | string | Instruction to include artifact in PR                    |

### Failure Output

- `errorType` (enum): One of `MissingContext`, `AmbiguousContext`, `AmbiguousCollectionFolder`, `DuplicateArtifact`, `MissingCollectionFolder`, `InvalidStructure`
- `message` (string): Human-readable actionable error
- `requiredFixes` (array): Specific missing/incorrect inputs to provide

## Behavioral Guarantees

- Must not silently generate duplicate endpoint request artifacts.
- Must stop with explicit errors for missing mandatory context.
- Must discover exactly one Bruno collection folder under `bruno/`; otherwise stop with actionable errors.
- Must stop with explicit create-or-correct guidance when target collection/controller folders are missing.
- Must use bounded context acquisition for large collections: structure-first scan, sample at most 3 `.bru` files, and cap `.bru` sampling to 400 lines before requesting clarification.
- Must derive HTTP method, route, path/query/header parameters, and request body shape from the referenced .NET source endpoint.
- Must keep generated content aligned with `bruno/process/PROCESS.md` naming and structure rules.
- Must avoid introducing secrets or sensitive literal values in output.

## Non-Goals

- Full collection regeneration from OpenAPI (handled by scaffolder).
- Automatic source code modifications outside the target `.bru` request artifact.
- Runtime endpoint verification against live services.
