# Example Usage Guide

## Sample Contract Coverage

`sample-swagger.json` is intentionally broader than a minimal demo. It exercises the v1 scaffolder against the main request and naming cases:

- `GET /events/{eventId}`: path parameter plus query parameter handling
- `POST /events`: nested `$ref` object body generation
- `GET /shareholders/lite`: header and query parameter handling
- `PUT /shareholders/{shareholderId}`: simple object request body
- `PATCH /shareholders/{shareholderId}`: summary-first naming with a distinct display name and stable slug despite sharing the underlying resource with the PUT endpoint
- `POST /shareholders/import`: top-level array-of-objects request body
- `POST /registrations`: `allOf` body composition
- `GET /health`: fallback controller and filename derivation when both tag and `operationId` are missing

## Why `petstore-swagger.json` Is Also Included

`petstore-swagger.json` is kept as a secondary compatibility sample because it is a widely recognized public OpenAPI example. It is useful for ad hoc smoke testing and for validating that the scaffolder works against a larger, less tailored contract.

It is not the primary checked-in reference sample for this repository. `sample-swagger.json` remains the canonical regression sample because it was intentionally shaped to cover the scaffolder-specific edge cases that matter for v1.

## Generate the Reference Collection

From `bruno/scaffolder/` run:

```powershell
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\examples\sample-swagger.json" `
    -ApiName "Event" `
    -OutputPath ".\examples"
```

This produces the checked-in reference collection at `examples\Contoso - Event\`.

## Naming Convention

The generated reference collection demonstrates the current naming approach:

- Bruno request names come from `summary` first, then `operationId`, then a method-plus-path fallback
- Request names shown in Bruno are readable Title Case labels
- `.bru` filenames on disk are lowercase kebab-case slugs
- HTTP method prefixes are introduced only when collisions need to be resolved within a controller folder

## Reference Output Structure

After generation, the example collection contains:

```text
examples/
└── Contoso - Event/
    ├── bruno.json
    ├── environments/
    │   ├── LOCAL.bru
    │   ├── DEV.bru
    │   └── TST.bru
    ├── Events/
    │   ├── folder.bru
    │   ├── create-event.bru
    │   ├── create-registration.bru
    │   └── get-event-detail.bru
    ├── Health/
    │   ├── folder.bru
    │   └── health-check.bru
    └── Shareholders/
        ├── folder.bru
        ├── get-shareholders-lite.bru
        ├── import-shareholders.bru
        ├── patch-shareholder.bru
        └── update-shareholder.bru
```

## Verification Notes

- `create-event.bru` should contain a nested `venue` object expanded from a `$ref`
- `import-shareholders.bru` should contain a JSON array body
- `create-registration.bru` should contain merged fields from the `allOf` schema
- `patch-shareholder.bru` and `update-shareholder.bru` prove summary-first naming produces readable Bruno labels and stable slugs
- `Health\health-check.bru` proves fallback grouping works without tags or `operationId`

## Regeneration Notes

If you rerun the scaffolder against an existing collection directory:

- current files are overwritten in place
- newly added endpoints create new `.bru` files
- files for removed endpoints remain on disk and are not deleted automatically

Use a clean output directory when you want a reference collection that matches the sample exactly.
