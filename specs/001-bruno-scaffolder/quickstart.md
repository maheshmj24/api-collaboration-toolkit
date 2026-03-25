# Quickstart: Bruno Scaffolder

## Prerequisites

- PowerShell 5.1+ (included with Windows 10/11) or PowerShell 7+
- An OpenAPI 3.0+ JSON file for your API
- [Bruno](https://www.usebruno.com/) installed (to open the generated collection)

## Generate a Collection in 3 Steps

### 1. Run the scaffolder

```powershell
cd bruno/scaffolder
.\Generate-BrunoCollection.ps1 -SwaggerPath "path\to\swagger.json" -ApiName "YourApiName"
```

This creates a collection at `.\bruno\Contoso - YourApiName\` with environments, controller folders, and `.bru` request files.

### 2. Open in Bruno

1. Open Bruno
2. Click `···` → **Open Collection**
3. Navigate to the generated `Contoso - YourApiName` folder

### 3. Configure and test

1. Select an environment (LOCAL, DEV, or TST)
2. Update `baseUrl` if needed
3. Add any required secrets to the `vars:secret` section
4. Send a request to verify connectivity

## Common Options

```powershell
# Custom company name and environments
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\swagger.json" `
    -ApiName "Experience" `
    -CompanyName "Fabrikam" `
    -Environments @("LOCAL", "DEV", "STAGING", "PROD")

# Custom output path
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\swagger.json" `
    -ApiName "Experience" `
    -OutputPath "C:\Collections"

# Verbose output for troubleshooting
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\swagger.json" `
    -ApiName "Experience" `
    -Verbose
```

## Verify Against the Reference Example

To confirm the scaffolder works correctly, run it against the included sample:

```powershell
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\examples\sample-swagger.json" `
    -ApiName "Event" `
    -OutputPath ".\examples"
```

Compare the output in `examples\Contoso - Event\` with the reference collection already checked in. The folder structure, environment files, and `.bru` request content should match.

## Configuration

Edit `bruno-scaffolder-config.json` to set organizational defaults:

```json
{
  "defaultCompanyName": "Contoso",
  "defaultEnvironments": ["LOCAL", "DEV", "TST"],
  "defaultBaseUrls": {
    "LOCAL": "https://localhost:5001/api",
    "DEV": "https://api-dev.contoso.com",
    "TST": "https://api-test.contoso.com"
  }
}
```

Command-line parameters always override configuration file values.

## Regeneration

When your API evolves, re-export the swagger and rerun the scaffolder against the same output path. Existing files are overwritten to match the current contract. Files not present in the new swagger are left in place.

## Troubleshooting

| Symptom                         | Cause                             | Fix                                                                 |
| ------------------------------- | --------------------------------- | ------------------------------------------------------------------- |
| "Cannot find path" error        | Swagger file path is wrong        | Check the file exists at the specified path                         |
| "Invalid JSON" error            | Swagger file is malformed         | Validate the file at [editor.swagger.io](https://editor.swagger.io) |
| Empty collection (no endpoints) | Swagger has no `paths`            | Check your OpenAPI spec has endpoint definitions                    |
| Missing request body in `.bru`  | Schema uses unsupported construct | Check for `$ref` chains or `allOf`/`oneOf` and report an issue      |
| Permission denied               | Output directory is read-only     | Run from a writable location or use `-OutputPath`                   |
