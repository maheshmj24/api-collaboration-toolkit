# .NET API Scaffolder + Prompt Sample

This sample API exists to test both scaffolder-based generation and prompt-based incremental Bruno request generation against real `.NET` controller methods.

## What This Covers

- Baseline Bruno collection generation via scaffolder
- Prompt/agent incremental `.bru` generation for new endpoints
- HTTP verb derivation from action attributes
- Route derivation from controller + action route templates
- Query/header/path parameter derivation from binding attributes
- Body schema derivation from DTO request types

## Run Locally

```powershell
cd examples/dotnet-api-sample
dotnet restore
dotnet run
```

Swagger UI should be available at `<base-url>/swagger` using the base URL shown in terminal output.

## How The Current Sample Was Produced

- The scaffolder was run for the sample collection baseline and existing APIs.
- The newly added API method `EventsController.SearchSessions` was then used to test prompt-based incremental generation.
- For that new method, the final `.bru` request artifact was created by running the Bruno prompt in agent mode.

This reflects the intended workflow:

1. Bootstrap or refresh baseline artifacts with scaffolder.
1. Add a new endpoint in source code.
1. Use the prompt in agent mode to generate only the new endpoint request artifact.

## Endpoint References For Prompt Testing

- `ShareholdersController.GetShareholdersLite`
- `ShareholdersController.GetShareholder`
- `ShareholdersController.CreateShareholder`
- `ShareholdersController.PatchShareholder`
- `EventsController.CreateRegistration`
- `EventsController.SearchSessions`

## Example Prompt Invocation

```text
Generate one Bruno request artifact using the attached prompt and references.
collectionName: Contoso - Sample
endpointReference: ShareholdersController.GetShareholdersLite
```

## Expected Prompt Behavior

The prompt/agent should derive (without manual input):

- HTTP method
- route template
- query/header/path parameters
- request body shape when applicable

The generated `.bru` request file should follow:

- `bruno/process/PROCESS.md`
- Existing structure under `bruno/scaffolder/examples/`

## Developer Test Guide (Scaffolder + Prompt)

Use this project as a sandbox to test both baseline generation and incremental updates.

### A) Test Scaffolder Regeneration

1. Add or modify one or more controller actions (for example in `Controllers/EventsController.cs`).
1. Update/export `swagger.json` for the sample project.
1. Run the scaffolder to regenerate the collection baseline.
1. Inspect generated files under `bruno/Contoso - Sample/`.

### B) Test Prompt Incremental Creation

1. Add one new controller action that does not yet have a corresponding `.bru` file.
1. Run the prompt in agent mode with `endpointReference` (and optional `collectionName`).
1. Verify exactly one new `.bru` file is created in the correct controller folder.

### C) Test Missing-File Recovery

1. Delete one existing `.bru` file under `bruno/Contoso - Sample/`.
1. Re-run prompt generation for that endpoint reference.
1. Verify the file is recreated with correct route, method, params, headers, and body placeholders.

### D) Test Duplicate Protection

1. Keep an existing `.bru` file in place for an endpoint.
1. Run the prompt again for the same endpoint.
1. Verify the agent asks for explicit update-vs-create behavior instead of silently duplicating.
