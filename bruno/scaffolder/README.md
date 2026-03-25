# Bruno Scaffolder

## Overview

The **Bruno Scaffolder** is a PowerShell tool that automatically generates complete Bruno API collections from Swagger/OpenAPI JSON specifications. It eliminates the manual overhead of creating individual `.bru` files and ensures consistency with organizational standards.

This tool follows the [Bruno Collection Structure and Process](../process/PROCESS.md) guidelines to create properly organized collections.

The intended convention is one Bruno collection per API project's `bruno/` directory. In a monorepo, each API project should own its own local `bruno/` folder rather than sharing a single repository-wide collection location.

## Features

- ✅ **Automated Structure Generation**: Creates the complete folder structure following organization standards
- ✅ **Environment Management**: Generates environment files for LOCAL, DEV, TST (and custom environments)
- ✅ **OpenAPI 3.0+ Parsing**: Parses OpenAPI 3.0+ JSON specifications (Swagger 2.0 requires conversion)
- ✅ **Smart Controller Organization**: Groups APIs by controller/tags automatically
- ✅ **Readable Request Naming**: Uses human-readable Bruno request names while keeping stable kebab-case `.bru` filenames on disk
- ✅ **Parameter Handling**: Automatically configures path parameters, query parameters, and headers
- ✅ **Request Body Support**: Generates JSON templates for object, array, nested `$ref`, and `allOf` request bodies
- ✅ **Verbose Troubleshooting**: Emits progress details only when run with `-Verbose`
- ✅ **Safe Regeneration**: Overwrites generated files and reports create vs overwrite counts without deleting unmatched files
- ✅ **Customizable Configuration**: Flexible settings for different organizations

## Prerequisites

- PowerShell 5.1 or later
- **OpenAPI 3.0+ JSON file** (if you have Swagger 2.0, convert it first using online tools)
- Bruno API client for testing generated collections

## Quick Start

### PowerShell Command

```powershell
.\Generate-BrunoCollection.ps1 -SwaggerPath ".\swagger.json" -ApiName "Experience"
```

For detailed progress output during generation:

```powershell
.\Generate-BrunoCollection.ps1 -SwaggerPath ".\swagger.json" -ApiName "Experience" -Verbose
```

## Usage Examples

### Basic Usage

```powershell
# Generate collection for "Experience API" using defaults
.\Generate-BrunoCollection.ps1 -SwaggerPath ".\swagger.json" -ApiName "Experience"
```

### Advanced Usage

```powershell
# Custom company name and environments
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\swagger.json" `
    -ApiName "UserService" `
    -CompanyName "Fabrikam" `
    -Environments @("LOCAL", "DEV", "STAGING", "PROD")

# With specific base URLs for environments
$baseUrls = @{
    "LOCAL" = "https://localhost:5001/api"
    "DEV" = "https://dev-api.contoso.com"
    "TST" = "https://test-api.contoso.com"
}
.\Generate-BrunoCollection.ps1 `
    -SwaggerPath ".\api-docs.json" `
    -ApiName "PaymentService" `
    -BaseUrls $baseUrls
```

## Generated Output

The scaffolder creates a complete Bruno collection structure following the [organizational standards](../process/PROCESS.md):

```text
bruno/
└── Contoso - <API Name>/
    ├── bruno.json                 # Collection configuration
    ├── environments/
    │   ├── LOCAL.bru             # Local development environment
    │   ├── DEV.bru               # Development environment
    │   └── TST.bru               # Test environment
    ├── <Controller1>/
    │   ├── <Endpoint1>.bru       # API endpoint file
    │   └── <Endpoint2>.bru
    └── <Controller2>/
        └── <Endpoint3>.bru
```

`OutputPath` should normally point to the API project's `bruno/` directory. The scaffolder then creates the single collection root inside that folder.

## Naming Convention

Generated requests use two related but separate names:

- **Bruno display name** (`meta.name`): human-readable Title Case, intended for scanning inside the Bruno client
- **`.bru` filename**: lowercase kebab-case slug, intended to stay stable and review-friendly in source control

Name derivation follows this order:

1. OpenAPI `summary`
2. `operationId`
3. HTTP method plus URL path fallback

Examples:

- Bruno shows `Get Event Detail` while the file is `get-event-detail.bru`
- Bruno shows `Create Registration` while the file is `create-registration.bru`
- If two endpoints in the same controller folder would otherwise collide, HTTP method prefixes are added only when needed to disambiguate them

## Compatibility

### OpenAPI Version Support

- ✅ **OpenAPI 3.0+**: Fully supported
- ⚠️ **Swagger 2.0**: Not directly supported - convert first

### Converting Swagger 2.0 to OpenAPI 3.0+

If you have a Swagger 2.0 file, convert it using:

- [Swagger Editor](https://editor.swagger.io/) - Import and export as OpenAPI 3.0
- [API Transformer](https://apimatic.io/transformer) - Online conversion tool
- Swagger CLI: `swagger-codegen-cli generate -i swagger2.json -l openapi -o openapi3.json`

## Configuration

### Default Settings

Customize organizational defaults by editing `bruno-scaffolder-config.json`:

- Company name
- Standard environments
- Base URL patterns
- Naming conventions

### Configuration Precedence

The scaffolder applies settings in this order:

1. Explicit command-line parameters
2. Values from `bruno-scaffolder-config.json`
3. Built-in defaults when the config file is missing or invalid

That means `-CompanyName`, `-Environments`, and `-BaseUrls` always win when you provide them.

### Command Line Parameters

| Parameter      | Required | Description                    | Default                    |
| -------------- | -------- | ------------------------------ | -------------------------- |
| `SwaggerPath`  | ✅       | Path to swagger.json file      | -                          |
| `ApiName`      | ✅       | Name for the API collection    | -                          |
| `OutputPath`   | ❌       | Output directory               | `.\bruno`                  |
| `CompanyName`  | ❌       | Company name for collection    | `Contoso`                  |
| `Environments` | ❌       | Environment names to create    | `@("LOCAL", "DEV", "TST")` |
| `BaseUrls`     | ❌       | Hash table of environment URLs | Auto-detected from swagger |

## Integration with Development Workflow

### During Development

1. Export swagger.json from your API
2. Run the scaffolder against that API project's local `bruno/` folder
3. Customize authentication, test data, and assertions
4. Commit .bru files alongside your code

### Code Reviews

- Include generated .bru files in pull requests
- Follow the [development guidelines](../process/PROCESS.md#development-guidelines) for PR requirements

### Team Onboarding

- New team members get consistent, up-to-date API collections
- Collections are automatically organized following team standards

### CI/CD Integration (Optional)

- Integrate scaffolder to auto-update collections when APIs change
- Ensure collections stay synchronized with API specifications

## Testing the Scaffolder

Try with the included sample:

```powershell
.\Generate-BrunoCollection.ps1 -SwaggerPath ".\examples\sample-swagger.json" -ApiName "Event" -OutputPath ".\examples"
```

This creates `examples\Contoso - Event\`, which is the checked-in reference collection.

The sample contract covers these v1 scenarios:

- `GET /events/{eventId}`: path and query parameters
- `POST /events`: nested `$ref` request body
- `GET /shareholders/lite`: header and query parameters
- `PUT` and `PATCH /shareholders/{shareholderId}`: summary-first request naming with distinct display names and stable kebab-case filenames
- `POST /shareholders/import`: top-level array request body
- `POST /registrations`: `allOf` request body composition
- `GET /health`: no tag and no `operationId` fallback grouping

## Benefits

- **Time Savings**: Eliminates manual creation of dozens of .bru files
- **Consistency**: Ensures all collections follow [organizational standards](../process/PROCESS.md)
- **Accuracy**: Collections always match API specifications
- **Maintenance**: Easy to regenerate when APIs evolve
- **Team Alignment**: Everyone uses the same collection structure

## Regeneration Behavior

Rerunning the scaffolder against an existing output path is safe and intentional:

- Existing generated files are overwritten to match the current contract
- New endpoint files are created when new paths appear
- Files that are no longer present in the swagger are left in place and are not deleted automatically
- The summary reports whether the run created new files or overwrote existing ones

The standard convention is still one collection per API project's `bruno/` location. If you point the scaffolder at a shared parent folder and vary the API name, you can create multiple sibling collection roots, but that is not the recommended layout for normal project usage.

## Troubleshooting

### Common Issues

1. **Execution Policy Error**:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Swagger File Not Found**: Verify the file path and ensure it's valid JSON

3. **Invalid JSON**: Validate the file at [Swagger Editor](https://editor.swagger.io) and rerun the scaffolder

4. **No Endpoints Generated**: Ensure the OpenAPI file contains operations under the `paths` section

5. **Permission Denied**: Ensure you have write permissions to the output directory

### Getting Help

Run with `-Verbose` flag for detailed output:

```powershell
.\Generate-BrunoCollection.ps1 -SwaggerPath ".\swagger.json" -ApiName "Experience" -Verbose
```

## Files Overview

- `Generate-BrunoCollection.ps1` - Main scaffolder script
- `bruno-scaffolder-config.json` - Configuration defaults
- `examples/` - Sample files and usage guide

## Next Steps

1. Generate your Bruno collection using the scaffolder
2. Follow the [Bruno Collection Guidelines](../process/PROCESS.md) for customization
3. Integrate into your development workflow
4. Share with your team for consistent API testing
