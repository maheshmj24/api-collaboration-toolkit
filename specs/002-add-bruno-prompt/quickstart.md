# Quickstart: Bruno Request Prompt

## Goal

Generate a PR-ready Bruno `.bru` request file for a newly created API endpoint using the reusable project prompt and markdown run guidance.

## Prerequisites

- Repository already follows Bruno process structure under `bruno/`.
- Target API endpoint/controller method already exists or is finalized enough to derive method, route, and payload shape.
- Baseline Bruno collection structure has already been bootstrapped once (scaffolder or compliant manual setup).

## Run Steps

### 1. Open the prompt assets

Open the prompt and run guide in `bruno/prompts/`:

- `bruno-request-generator.prompt.md`
- `README.md`

### 2. Provide endpoint context

Supply at minimum:

- Endpoint method reference

Optional only when inference is ambiguous:

- Collection name confirmation
- Controller name override

### 3. Generate the request artifact

Run the prompt in Copilot/agent with your endpoint context and existing in-repo Bruno artifacts.

For large collections, follow bounded context behavior:

- Prefer structure-first scan (folders and filenames) before reading file contents.
- Sample at most 3 `.bru` files for style inference.
- Cap sampled `.bru` content to 400 lines before asking for focused clarification.

Expected result:

- One new `.bru` request artifact under the correct controller folder in the target collection.

### 4. Validate output

Check that generated content matches Bruno conventions:

- Correct collection/controller path
- Request method and route (`{{baseUrl}}` + path) match source-derived endpoint metadata
- Query/header/path variables and `body:json` are source-derived from the controller method
- No secrets or environment-specific sensitive values

### 5. Include in pull request

Commit the generated `.bru` file with the API endpoint code changes in the same PR.

## Troubleshooting

- Prompt cannot generate: Likely cause is missing `endpointReference` or unresolved collection detection. Fix by providing endpoint reference and ensuring exactly one collection exists under `bruno/`.
- File created in wrong folder: Likely cause is controller inference ambiguity. Fix by providing controller override and rerun.
- Duplicate request conflict: Likely cause is existing `.bru` matches endpoint. Fix by choosing explicit update vs create strategy.
- Body template inaccurate: Likely cause is source action signature ambiguity. Fix by clarifying endpoint reference and regenerating.

## Done Criteria

- New endpoint has corresponding `.bru` request file.
- File location and naming follow process guidelines.
- PR includes endpoint code + generated Bruno artifact together.
- Optional sample harness path for repeatable validation: `examples/dotnet-api-sample/`.
