# Data Model: Bruno Request Prompt

**Phase**: 1 - Design & Contracts  
**Date**: 2026-03-18

## Entities

### 1. Prompt Artifact

Reusable markdown prompt file that guides generation of a single Bruno request artifact for one endpoint.

| Field                 | Type         | Required | Description                                 |
| --------------------- | ------------ | -------- | ------------------------------------------- |
| `name`                | string       | Yes      | Human-readable prompt name                  |
| `purpose`             | string       | Yes      | Declares prompt goal and boundaries         |
| `requiredInputs`      | list[string] | Yes      | Required user/context inputs to proceed     |
| `references`          | list[path]   | Yes      | Process/example files to ground generation  |
| `generationRules`     | list[string] | Yes      | Deterministic mapping and formatting rules  |
| `validationChecklist` | list[string] | Yes      | Output checks before finalizing             |
| `errorHandlingRules`  | list[string] | Yes      | Missing context/duplicate handling behavior |

### 2. Prompt Invocation Context

Data provided by developer and workspace analysis for one endpoint request generation run.

| Field                  | Type                                 | Required | Description                                                 |
| ---------------------- | ------------------------------------ | -------- | ----------------------------------------------------------- |
| `collectionName`       | string                               | No       | Optional collection name confirmation provided by developer |
| `endpointReference`    | string                               | Yes      | Source controller method or endpoint identifier             |
| `controllerName`       | string                               | No       | Optional override when controller resolution is ambiguous   |
| `httpMethod`           | enum(GET,POST,PUT,PATCH,DELETE,HEAD) | Derived  | Derived from controller/action attributes                   |
| `routeTemplate`        | string                               | Derived  | Derived from controller/action route metadata               |
| `queryParameters`      | array of objects                     | Derived  | Derived from action signature and binding attributes        |
| `headerParameters`     | array of objects                     | Derived  | Derived from action signature and binding attributes        |
| `requestBodyShape`     | object                               | Derived  | Derived from payload DTO/signature for body methods         |
| `targetCollectionPath` | path                                 | Derived  | Discovered single Bruno collection folder under `bruno/`    |
| `contextBudget`        | object                               | Derived  | Bounded `.bru` sampling limits for style inference          |

### 3. Bruno Request Artifact

Generated `.bru` file for a single endpoint operation.

| Field            | Type   | Required | Description                                            |
| ---------------- | ------ | -------- | ------------------------------------------------------ |
| `relativePath`   | path   | Yes      | `bruno/Contoso - <API>/<Controller>/<RequestName>.bru` |
| `metaName`       | string | Yes      | Friendly request name                                  |
| `requestSection` | object | Yes      | Method, URL, auth inheritance, body mode               |
| `queryBlock`     | object | No       | `params:query` when query params exist                 |
| `headersBlock`   | object | No       | `headers` when headers exist                           |
| `preRequestVars` | object | No       | `vars:pre-request` for path parameters                 |
| `bodyJson`       | json   | No       | Placeholder JSON for payload methods                   |
| `settings`       | object | Yes      | Bruno settings defaults                                |

### 4. Prompt Run Guide

Developer-facing markdown for running the prompt consistently.

| Field                | Type         | Required | Description                           |
| -------------------- | ------------ | -------- | ------------------------------------- |
| `prerequisites`      | list[string] | Yes      | What must exist before invocation     |
| `invocationTemplate` | string       | Yes      | Copy/paste run pattern                |
| `inputChecklist`     | list[string] | Yes      | Minimum endpoint context required     |
| `outputChecklist`    | list[string] | Yes      | Validate generated `.bru` correctness |
| `prChecklist`        | list[string] | Yes      | Required PR inclusion steps           |

## Relationships

- One `Prompt Artifact` is used by many `Prompt Invocation Context` runs.
- Each `Prompt Invocation Context` produces exactly one `Bruno Request Artifact` unless duplicate handling interrupts flow.
- One `Prompt Run Guide` documents usage for one or more `Prompt Artifact` files in `bruno/prompts/`.

## Validation Rules

- `endpointReference` is mandatory before generation.
- If `collectionName` is provided, it must match the discovered single collection folder name.
- `httpMethod`, `routeTemplate`, query/header/path parameters, and request body shape must be derived from source analysis.
- Exactly one collection folder must exist under `bruno/`; otherwise generation must stop with actionable guidance.
- `targetCollectionPath` must exist and follow Bruno process structure, or the workflow must stop and return explicit create-or-correct guidance.
- Style inference must respect context-budget limits (max 3 `.bru` files and max 400 `.bru` lines) before requesting clarification.
- If existing `.bru` for same endpoint is found, workflow requires explicit update/create decision.
- Generated artifact must not contain secret literal values.
- Output path and naming must match process conventions and existing sibling requests.

## State Transitions

```text
Draft Prompt
  ->
Prompt Invoked (with input context)
  ->
Context Validation
  ->
Generation
  ->
Output Validation
  ->
PR-Ready Artifact
```

Failure transitions:

- Context Validation -> Blocked (missing/ambiguous inputs)
- Generation -> Blocked (duplicate without explicit action)
- Output Validation -> Rework Required
