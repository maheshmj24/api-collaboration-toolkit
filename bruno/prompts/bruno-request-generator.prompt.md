---
description: 'Generate one Bruno .bru request artifact from an endpoint/controller method using in-repo Bruno assets and source-derived endpoint metadata.'
---

# Bruno Request Generator Prompt (Copy This Exact Block)

```text
You are helping me add one Bruno request file for a .NET API endpoint.

Inputs:
- endpointReference: <ControllerName.MethodName>
- collectionName (optional confirmation): <COLLECTION_NAME>
- controllerName (optional override): <ControllerName>

Context source (no external attachments required):
- existing `bruno/` folder structure in the current repository
- sibling `.bru` files and environments in the target collection
- endpoint source code for `endpointReference`

Task:
1. Discover the target collection in `bruno/` by locating child folder(s) that contain `bruno.json`.
2. Enforce single-collection policy:
   - If no collection folder is found, stop with `MissingCollectionFolder`.
   - If multiple collection folders are found, stop with `AmbiguousCollectionFolder` and list candidates.
   - If `collectionName` is provided and does not match the discovered folder, stop with `AmbiguousContext`.
3. Apply context-budget mode before reading files:
   - Do a structure-first scan (folder names + filenames) and avoid full-file reads until needed.
   - Read at most 3 existing `.bru` files for style inference.
   - Prefer files from the same controller folder; if none exist, sample up to 2 from other controllers.
   - Keep total `.bru` context to at most 400 lines.
   - If conventions are still ambiguous after limits, stop with `AmbiguousContext` and ask one focused clarification.
4. Analyze the .NET source for endpointReference and derive everything from code:
   - HTTP method
   - route template
   - path parameters
   - query parameters
   - header requirements
   - body shape
5. Generate exactly one .bru request artifact in the correct Bruno collection/controller structure.
6. Follow repository Bruno conventions (naming, structure, placeholders, no secrets).
7. Use existing in-repo Bruno artifacts as primary convention reference; do not require external process documents.
8. If the controller folder is missing, stop with `MissingCollectionFolder` and tell me exactly what to create/fix.
9. If a matching request file already exists, do not overwrite silently; ask for explicit update-vs-create choice.

Output format:
- generatedFilePath
- generationSummary
- validationResults
- nextAction

Validation requirements:
- Exactly one collection exists under `bruno/`, or an explicit error is returned
- Context budget limits are respected (no full-collection `.bru` scan)
- Method and URL match derived source
- Query/header/path/body sections match derived source
- Output path and naming follow Bruno process conventions
- No secret literal values
```
