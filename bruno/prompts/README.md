# Bruno Prompt Workflow

## Purpose

Generate one Bruno `.bru` request file for a new .NET API endpoint with minimal manual input.

## Prerequisite

Before running the prompt, the API project must already have a `bruno/` folder that follows the defined process in `bruno/process/PROCESS.md` (single collection structure, environments, and controller folders).

If this baseline is missing, bootstrap it first using the scaffolder or by creating the structure manually according to the process guide.

## Prompt File

- `bruno-request-generator.prompt.md`

## Exact Prompt To Copy

Copy the exact block from `bruno/prompts/bruno-request-generator.prompt.md` and paste it into Copilot/agent chat.

## Quick Start

1. Open `bruno/prompts/bruno-request-generator.prompt.md`.
1. Copy the exact prompt block into Copilot/agent chat.
1. Set required input:
   - `endpointReference`
1. Optional only if needed:
   - `collectionName` (confirmation only)
   - `controllerName`
1. No external attachments are required.
   - The prompt uses in-repo context from your existing `bruno/` folder and endpoint source code.
1. The prompt assumes one collection per API project and will fail fast if zero or multiple collections are found under `bruno/`.
1. Run prompt.
1. Commit generated `.bru` in same PR as endpoint code.

## Concrete Invocation Example

Use this input replacement:

```text
endpointReference: ShareholdersController.GetShareholdersLite
```

Sample harness endpoint example:

```text
endpointReference: EventsController.CreateRegistration
```

## Validate Before Commit

- Output path is correct under the discovered collection path: `bruno/<Collection>/<Controller>/`
- Method and route match source controller action
- Query/header/path/body sections were derived from source
- No secrets are embedded

## Large Collection Optimization

Use a low-token context strategy when the collection is large:

1. Scan structure first (folders and filenames), not full file contents.
1. Sample only up to 3 existing `.bru` files for style inference.
1. Prefer samples from the same controller folder as the target endpoint.
1. Keep total sampled `.bru` content under 400 lines.
1. If conventions are still unclear after sampling, ask one focused clarification rather than reading more files.

## Optional Local Test Harness

Use `examples/dotnet-api-sample/` for repeatable local tests.

Common sample endpoint references:

- `ShareholdersController.GetShareholdersLite`
- `ShareholdersController.GetShareholder`
- `ShareholdersController.CreateShareholder`
- `ShareholdersController.PatchShareholder`
- `EventsController.CreateRegistration`
