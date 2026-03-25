#Requires -Version 5.1

<#
.SYNOPSIS
    Bruno API Collection Scaffolder - Generates Bruno collection from Swagger/OpenAPI specification

.DESCRIPTION
    This script parses a Swagger/OpenAPI JSON file and generates a complete Bruno collection 
    following the organization's standardized structure with proper folder organization,
    environment files, and .bru API files.

.PARAMETER SwaggerPath
    Path to the swagger.json or OpenAPI JSON file

.PARAMETER OutputPath
    Directory where the Bruno collection will be created (default: ./bruno)

.PARAMETER ApiName
    Name of the API for the collection folder (e.g., "Experience", "UserManagement")

.PARAMETER CompanyName
    Company name for the collection (default: "Contoso")

.PARAMETER Environments
    Array of environment names to create (default: @("LOCAL", "DEV", "TST"))

.PARAMETER BaseUrls
    Hashtable of environment base URLs (optional)

.EXAMPLE
    .\Generate-BrunoCollection.ps1 -SwaggerPath ".\swagger.json" -ApiName "Experience"

.EXAMPLE
    .\Generate-BrunoCollection.ps1 -SwaggerPath ".\api-docs.json" -ApiName "UserService" -CompanyName "Fabrikam" -Environments @("LOCAL", "DEV", "STAGING", "PROD")

.NOTES
    Author: Bruno Scaffolder
    Version: 1.0
    Follows the organization's Bruno collection standards
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$SwaggerPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\bruno",
    
    [Parameter(Mandatory = $true)]
    [string]$ApiName,
    
    [Parameter(Mandatory = $false)]
    [string]$CompanyName = "Contoso",
    
    [Parameter(Mandatory = $false)]
    [string[]]$Environments = @("LOCAL", "DEV", "TST"),
    
    [Parameter(Mandatory = $false)]
    [hashtable]$BaseUrls = @{}
)

#region Helper Functions

# Color coding for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput $Message "Red" }

# Function to sanitize file and folder names
function Get-SanitizedName {
    param([string]$Name)
    
    # Remove invalid characters and convert to PascalCase
    $sanitized = $Name -replace '[^\w\s-]', '' -replace '\s+', ' '
    $words = $sanitized -split '[-\s_]' | Where-Object { $_ -ne '' }
    return ($words | ForEach-Object { 
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() 
        }) -join ''
}

# Function to normalize a name into word tokens
function Get-NormalizedWords {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $normalized = $Text -creplace '([A-Z]+)([A-Z][a-z])', '${1} ${2}'
    $normalized = $normalized -creplace '([a-z0-9])([A-Z])', '${1} ${2}'
    $normalized = $normalized -replace '[^\w]+', ' '
    $normalized = $normalized.Trim()

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    return @($normalized -split '\s+' | Where-Object { $_ -ne '' })
}

function Convert-WordsToTitleCase {
    param([string[]]$Words)

    $formattedWords = @()
    foreach ($word in $Words) {
        if ([string]::IsNullOrWhiteSpace($word)) {
            continue
        }

        if ($word.Length -le 4 -and $word -cmatch '^[A-Z0-9]+$') {
            $formattedWords += $word.ToUpper()
            continue
        }

        if ($word.Length -eq 1) {
            $formattedWords += $word.ToUpper()
            continue
        }

        $formattedWords += ($word.Substring(0, 1).ToUpper() + $word.Substring(1).ToLower())
    }

    return ($formattedWords -join ' ').Trim()
}

function Convert-WordsToKebabCase {
    param([string[]]$Words)

    $segments = @()
    foreach ($word in $Words) {
        if (-not [string]::IsNullOrWhiteSpace($word)) {
            $segments += $word.ToLower()
        }
    }

    return ($segments -join '-').Trim('-')
}

function Get-PathNameWords {
    param(
        [string]$Method,
        [string]$Path,
        [switch]$IncludeMethod
    )

    $words = New-Object System.Collections.Generic.List[string]
    $resourceWords = New-Object System.Collections.Generic.List[string]
    $parameterWords = New-Object System.Collections.Generic.List[string]
    $methodWord = if ($Method) { $Method.Substring(0, 1).ToUpper() + $Method.Substring(1).ToLower() } else { 'Request' }

    if ($IncludeMethod) {
        $words.Add($methodWord)
    }

    $pathSegments = @($Path -split '/' | Where-Object { $_ -ne '' })
    foreach ($segment in $pathSegments) {
        if ($segment -match '^\{(.+)\}$') {
            foreach ($word in (Get-NormalizedWords $Matches[1])) {
                $parameterWords.Add($word)
            }
            continue
        }

        foreach ($word in (Get-NormalizedWords $segment)) {
            if ($word.ToLower() -notin @('api', 'v1', 'v2', 'v3')) {
                $resourceWords.Add($word)
            }
        }
    }

    if ($resourceWords.Count -gt 0 -and $resourceWords[0].ToLower() -eq $methodWord.ToLower()) {
        $resourceWords.RemoveAt(0)
    }

    if ($resourceWords.Count -eq 0) {
        $resourceWords.Add('Request')
    }

    foreach ($word in $resourceWords) {
        $words.Add($word)
    }

    if ($parameterWords.Count -gt 0) {
        $words.Add('By')
        foreach ($word in $parameterWords) {
            $words.Add($word)
        }
    }

    return @($words.ToArray())
}

function Get-BrunoRequestNameWords {
    param(
        [string]$Method,
        [string]$Path,
        [string]$OperationId,
        [string]$Summary
    )

    $summaryWords = @(Get-NormalizedWords $Summary)
    if ($summaryWords.Count -gt 0) {
        return $summaryWords
    }

    $operationWords = @(Get-NormalizedWords $OperationId)
    if ($operationWords.Count -gt 0) {
        return $operationWords
    }

    return @(Get-PathNameWords -Method $Method -Path $Path -IncludeMethod)
}

function Get-BrunoDisplayName {
    param(
        [string]$Method,
        [string]$Path,
        [string]$OperationId,
        [string]$Summary
    )

    $words = @(Get-BrunoRequestNameWords -Method $Method -Path $Path -OperationId $OperationId -Summary $Summary)
    return Convert-WordsToTitleCase $words
}

function Get-BrunoFileSlug {
    param(
        [string]$Method,
        [string]$Path,
        [string]$OperationId,
        [string]$Summary
    )

    $words = @(Get-BrunoRequestNameWords -Method $Method -Path $Path -OperationId $OperationId -Summary $Summary)
    return Convert-WordsToKebabCase $words
}

function Add-MethodPrefixToDisplayName {
    param(
        [string]$Method,
        [string]$DisplayName
    )

    $methodWord = $Method.Substring(0, 1).ToUpper() + $Method.Substring(1).ToLower()
    if ($DisplayName -match "^$([regex]::Escape($methodWord))(\s|$)") {
        return $DisplayName
    }

    return "$methodWord $DisplayName"
}

function Add-MethodPrefixToSlug {
    param(
        [string]$Method,
        [string]$Slug
    )

    $methodSlug = $Method.ToLower()
    if ($Slug -like "$methodSlug-*") {
        return $Slug
    }

    return "$methodSlug-$Slug"
}

function Add-PathQualifierToDisplayName {
    param(
        [string]$DisplayName,
        [string]$Path
    )

    $qualifier = Convert-WordsToTitleCase @(Get-PathNameWords -Path $Path)
    if ([string]::IsNullOrWhiteSpace($qualifier) -or $DisplayName.EndsWith(" - $qualifier")) {
        return $DisplayName
    }

    return "$DisplayName - $qualifier"
}

function Add-PathQualifierToSlug {
    param(
        [string]$Slug,
        [string]$Path
    )

    $qualifier = Convert-WordsToKebabCase @(Get-PathNameWords -Path $Path)
    if ([string]::IsNullOrWhiteSpace($qualifier) -or $Slug -like "*-$qualifier") {
        return $Slug
    }

    return "$Slug-$qualifier"
}

# Function to extract controller name from path or tags
function Get-ControllerName {
    param(
        [string]$Path,
        [array]$Tags,
        [string]$OperationId
    )
    
    # Try to get from tags first - use the tag name as-is
    if ($Tags -and $Tags.Count -gt 0) {
        return $Tags[0]  # Use the original tag name without modification
    }
    
    # Try to extract from operationId (e.g., "UsersController_GetUser" -> "Users")
    if ($OperationId -and $OperationId -match '^(\w+)Controller_') {
        return Get-SanitizedName $Matches[1]
    }
    
    # Fallback: use first segment of path
    $pathSegments = @($Path -split '/' | Where-Object { $_ -ne '' -and $_ -notmatch '^\{.*\}$' })
    if ($pathSegments.Count -gt 0) {
        return Get-SanitizedName $pathSegments[0]
    }
    
    return "General"
}

# Function to create Bruno environment file
function New-BrunoEnvironment {
    param(
        [string]$Name,
        [string]$BaseUrl,
        [string]$FilePath
    )
    
    $envContent = @"
vars {
  baseUrl: $BaseUrl
}
vars:secret [

]
"@
    
    $envContent | Out-File -FilePath $FilePath -Encoding UTF8
}

# Function to create Bruno collection.bru file
function New-BrunoCollectionFile {
    param(
        [string]$CollectionName,
        [string]$FilePath
    )
    
    $collectionContent = @"
meta {
  name: $CollectionName
  type: collection
}
"@
    
    $collectionContent | Out-File -FilePath $FilePath -Encoding UTF8
}

# Function to create Bruno folder.bru file
function New-BrunoFolderFile {
    param(
        [string]$FolderName,
        [string]$FilePath
    )
    
    $folderContent = @"
meta {
  name: $FolderName
  type: folder
}
"@
    
    $folderContent | Out-File -FilePath $FilePath -Encoding UTF8
}

# Function to load configuration from JSON file
function Get-BrunoScaffolderConfig {
    param([string]$ConfigPath)
    
    $defaultConfig = @{
        defaultCompanyName  = "Contoso"
        defaultEnvironments = @("LOCAL", "DEV", "TST")
        defaultBaseUrls     = @{
            "LOCAL" = "https://localhost:5001/api"
            "DEV"   = "https://api-dev.contoso.com"
            "TST"   = "https://api-test.contoso.com"
        }
        apiNamingRules      = @{
            removePrefixes = @("API", "Service", "Controller")
            removeSuffixes = @("API", "Service", "Controller")
            usePascalCase  = $true
        }
    }
    
    if (Test-Path $ConfigPath) {
        try {
            $jsonConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $jsonConfig
        }
        catch {
            Write-Warning "Failed to load config file '$ConfigPath'. Using defaults."
            return $defaultConfig
        }
    }
    else {
        Write-Warning "Config file not found at '$ConfigPath'. Using built-in defaults (CompanyName='Contoso', Environments=LOCAL/DEV/TST). Create a config file to customize."
        return $defaultConfig
    }
}

#region JSON Schema Processing

# Function to generate JSON body from Swagger schema
function Get-JsonBodyFromSchema {
    param(
        [object]$Schema,
        [object]$SwaggerContent,
        [System.Collections.Generic.HashSet[string]]$Visited = $null
    )
    
    if (-not $Schema) { return $null }
    
    # Initialize visited set on first call
    if ($null -eq $Visited) {
        $Visited = [System.Collections.Generic.HashSet[string]]::new()
    }
    
    # Handle schema references
    if ($Schema.'$ref') {
        $refString = $Schema.'$ref'
        
        # Guard against circular references
        if (-not $Visited.Add($refString)) {
            return "{{CIRCULAR_REF}}"
        }
        
        $refPath = $refString -replace '#/', '' -replace '/', '.'
        $refParts = $refPath -split '\.'
        $resolvedSchema = $SwaggerContent
        foreach ($part in $refParts) {
            $resolvedSchema = $resolvedSchema.$part
        }
        $result = Get-JsonBodyFromSchema -Schema $resolvedSchema -SwaggerContent $SwaggerContent -Visited $Visited
        [void]$Visited.Remove($refString)
        return $result
    }
    
    # Handle allOf — merge properties from all sub-schemas
    if ($Schema.allOf) {
        $merged = @{}
        foreach ($subSchema in $Schema.allOf) {
            $subResult = Get-JsonBodyFromSchema -Schema $subSchema -SwaggerContent $SwaggerContent -Visited $Visited
            if ($subResult -is [hashtable]) {
                foreach ($key in $subResult.Keys) {
                    $merged[$key] = $subResult[$key]
                }
            }
        }
        return $merged
    }
    
    # Handle oneOf / anyOf — use the first sub-schema
    if ($Schema.oneOf) {
        return Get-JsonBodyFromSchema -Schema $Schema.oneOf[0] -SwaggerContent $SwaggerContent -Visited $Visited
    }
    if ($Schema.anyOf) {
        return Get-JsonBodyFromSchema -Schema $Schema.anyOf[0] -SwaggerContent $SwaggerContent -Visited $Visited
    }
    
    switch ($Schema.type) {
        'object' {
            $obj = @{}
            if ($Schema.properties) {
                foreach ($prop in $Schema.properties.PSObject.Properties) {
                    $propName = $prop.Name
                    $propSchema = $prop.Value
                    $obj[$propName] = Get-JsonBodyFromSchema -Schema $propSchema -SwaggerContent $SwaggerContent -Visited $Visited
                }
            }
            return $obj
        }
        'array' {
            # Generate sample item for arrays with schema references
            if ($Schema.items) {
                $sampleItem = Get-JsonBodyFromSchema -Schema $Schema.items -SwaggerContent $SwaggerContent -Visited $Visited
                if ($sampleItem) {
                    return @($sampleItem)
                }
            }
            return @()
        }
        'string' { return "{{PLACEHOLDER}}" }
        'integer' { return 0 }
        'number' { return 0.0 }
        'boolean' { return $false }
        default { return "{{PLACEHOLDER}}" }
    }
}

#endregion

#region Bruno File Generation

function New-BrunoApiFile {
    param(
        [string]$Method,
        [string]$Path,
        [string]$DisplayName,
        [string]$Description,
        [hashtable]$Parameters,
        [object]$RequestBody,
        [object]$SwaggerContent,
        [string]$FilePath
    )
    
    $method = $Method.ToLower()
    $url = "{{baseUrl}}$Path"
    
    # Replace path parameters with Bruno variable syntax
    if ($Parameters -and $Parameters.ContainsKey('path')) {
        foreach ($param in $Parameters['path']) {
            $paramName = $param.name
            $url = $url -replace "\{$paramName\}", "{{$paramName}}"
        }
    }
    
    $content = @"
meta {
    name: $DisplayName
  type: http
  seq: 1
}

$method {
  url: $url
  body: none
  auth: inherit
}
"@

    # Add query parameters
    if ($Parameters -and $Parameters.ContainsKey('query') -and $Parameters['query'].Count -gt 0) {
        $content += "`n`nparams:query {`n"
        foreach ($param in $Parameters['query']) {
            $required = if ($param.required) { "" } else { "~" }
            $content += "  $required$($param.name): {{PLACEHOLDER}}`n"
        }
        $content += "}`n"
    }
    
    # Add headers
    if ($Parameters -and $Parameters.ContainsKey('header') -and $Parameters['header'].Count -gt 0) {
        $content += "`nheaders {`n"
        foreach ($param in $Parameters['header']) {
            $content += "  $($param.name): {{PLACEHOLDER}}`n"
        }
        $content += "}`n"
    }
    
    # Add request body for POST/PUT/PATCH
    if ($RequestBody -and $method -in @('post', 'put', 'patch')) {
        $content = $content -replace 'body: none', 'body: json'
        $content += "`nbody:json {`n"
        
        # Try to generate JSON from schema
        $jsonBody = $null
        if ($RequestBody.content) {
            $contentTypes = @('application/json', 'application/*+json', 'text/json')
            foreach ($contentType in $contentTypes) {
                if ($RequestBody.content.$contentType -and $RequestBody.content.$contentType.schema) {
                    $schema = $RequestBody.content.$contentType.schema
                    $jsonObj = Get-JsonBodyFromSchema -Schema $schema -SwaggerContent $SwaggerContent
                    if ($null -ne $jsonObj) {
                        # Determine if root schema is an array type
                        $isRootArray = $false
                        $rootSchema = $schema
                        if ($rootSchema.'$ref') {
                            $refPath = $rootSchema.'$ref' -replace '#/', '' -replace '/', '.'
                            $refParts = $refPath -split '\.'
                            $resolved = $SwaggerContent
                            foreach ($part in $refParts) { $resolved = $resolved.$part }
                            $rootSchema = $resolved
                        }
                        if ($rootSchema.type -eq 'array') { $isRootArray = $true }
                        
                        if ($isRootArray) {
                            # Force array wrapping — ConvertTo-Json unwraps single-element arrays
                            $innerItem = $jsonObj
                            if ($jsonObj -is [array] -and $jsonObj.Count -gt 0) { $innerItem = $jsonObj[0] }
                            $innerJson = $innerItem | ConvertTo-Json -Depth 10 -Compress:$false
                            $jsonBody = "[$innerJson]"
                        }
                        else {
                            $jsonBody = $jsonObj | ConvertTo-Json -Depth 10 -Compress:$false
                        }
                        break
                    }
                }
            }
        }
        
        if ($jsonBody) {
            # Format the JSON nicely with proper indentation
            $formattedJson = $jsonBody -split "`n" | ForEach-Object { "  $_" }
            $content += $formattedJson -join "`n"
        }
        else {
            $content += "  {`n    `"example`": `"{{PLACEHOLDER}}`"`n  }"
        }
        
        $content += "`n}`n"
    }
    
    # Add path variables section if any
    if ($Parameters -and $Parameters.ContainsKey('path') -and $Parameters['path'].Count -gt 0) {
        $content += "`nvars:pre-request {`n"
        foreach ($param in $Parameters['path']) {
            $content += "  $($param.name): {{PLACEHOLDER}}`n"
        }
        $content += "}`n"
    }
    
    # Add settings block
    $content += "`nsettings {`n  encodeUrl: true`n  timeout: 0`n}`n"
    
    $content | Out-File -FilePath $FilePath -Encoding UTF8
}

#endregion

#region Main Execution

# Main execution
try {
    Write-Verbose "🚀 Starting Bruno Collection Scaffolder"
    
    # Load configuration
    $configPath = Join-Path $PSScriptRoot "bruno-scaffolder-config.json"
    $config = Get-BrunoScaffolderConfig -ConfigPath $configPath
    
    # Use config defaults only when parameters were not explicitly provided (T013/R-004)
    if (-not $PSBoundParameters.ContainsKey('CompanyName')) {
        $CompanyName = $config.defaultCompanyName
    }
    if (-not $PSBoundParameters.ContainsKey('Environments')) {
        $Environments = $config.defaultEnvironments
    }
    if (-not $PSBoundParameters.ContainsKey('BaseUrls') -or $BaseUrls.Count -eq 0) {
        $BaseUrls = @{}
        $config.defaultBaseUrls.PSObject.Properties | ForEach-Object {
            $BaseUrls[$_.Name] = $_.Value
        }
    }
    
    # T010: Probe output path permissions before doing any work
    $probeDir = (Resolve-Path -Path $OutputPath -ErrorAction SilentlyContinue).Path
    if (-not $probeDir) {
        try {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            $probeDir = (Resolve-Path -Path $OutputPath).Path
        }
        catch {
            Write-Error "❌ Cannot create output directory '$OutputPath'. Check that you have write permissions to this location."
            exit 1
        }
    }
    $probeFile = Join-Path $probeDir ".scaffolder-probe-$(Get-Random).tmp"
    try {
        [System.IO.File]::WriteAllText($probeFile, "probe")
        Remove-Item $probeFile -Force
    }
    catch {
        Write-Error "❌ Cannot write to output directory '$OutputPath'. Check that you have write permissions to this location."
        exit 1
    }
    
    Write-Verbose "Reading Swagger file: $SwaggerPath"
    
    # T008: Read and parse Swagger JSON with structured error handling
    $rawJson = Get-Content -Path $SwaggerPath -Raw
    try {
        $swaggerContent = $rawJson | ConvertFrom-Json
    }
    catch {
        Write-Error "❌ The file '$SwaggerPath' is not valid JSON. Please check the file format."
        Write-Error "   Detail: $($_.Exception.Message)"
        Write-Error "   Tip: Validate your file at https://editor.swagger.io"
        exit 1
    }
    
    # Create collection structure
    $collectionName = "$CompanyName - $ApiName"
    $collectionPath = Join-Path $OutputPath $collectionName
    
    Write-Verbose "Creating collection: $collectionName"
    
    # Track regeneration stats (T016/R-005)
    $isRegeneration = Test-Path $collectionPath
    $filesCreated = 0
    $filesOverwritten = 0
    
    # Create main collection directory
    if ($isRegeneration) {
        Write-Warning "Collection directory already exists. Contents will be merged/overwritten."
    }
    New-Item -Path $collectionPath -ItemType Directory -Force | Out-Null
    
    # Create environments directory and files
    $environmentsPath = Join-Path $collectionPath "environments"
    New-Item -Path $environmentsPath -ItemType Directory -Force | Out-Null
    
    Write-Verbose "Creating environment files..."
    foreach ($env in $Environments) {
        $envFileName = "$env.bru"
        $envFilePath = Join-Path $environmentsPath $envFileName
        
        if (Test-Path $envFilePath) { $filesOverwritten++ } else { $filesCreated++ }
        
        # Use provided base URL or create placeholder
        $baseUrl = if ($BaseUrls.ContainsKey($env)) {
            $BaseUrls[$env]
        }
        elseif ($swaggerContent.host -and $swaggerContent.basePath) {
            "https://$($swaggerContent.host)$($swaggerContent.basePath)"
        }
        elseif ($swaggerContent.servers -and $swaggerContent.servers.Count -gt 0) {
            $swaggerContent.servers[0].url
        }
        else {
            "https://api.example.com/v1"
        }
        
        New-BrunoEnvironment -Name $env -BaseUrl $baseUrl -FilePath $envFilePath
        Write-Verbose "  ✓ Created $envFileName"
    }
    
    # T009: Guard against swagger with no paths
    if (-not $swaggerContent.paths -or ($swaggerContent.paths.PSObject.Properties | Measure-Object).Count -eq 0) {
        # Create the collection skeleton (bruno.json) even with no endpoints
        $collectionConfig = @"
{
  "version": "1",
  "name": "$collectionName",
  "type": "collection",
  "ignore": [
    "node_modules",
    ".git"
  ]
}
"@
        $brunoJsonPath = Join-Path $collectionPath "bruno.json"
        $collectionConfig | Out-File -FilePath $brunoJsonPath -Encoding UTF8
        
        Write-Warning "⚠️ The swagger file contains no API paths. Collection skeleton created with environments but no endpoint files."
        Write-Warning "   Check that your OpenAPI spec has endpoint definitions under the 'paths' section."
        Write-Success "`n📊 Summary:"
        Write-Host "   Collection: $collectionName"
        Write-Host "   Location: $collectionPath"
        Write-Host "   Environments: $($Environments.Count) ($($Environments -join ', '))"
        Write-Host "   Endpoints: 0 (no paths found in swagger)"
        return
    }
    
    # Parse API paths and create .bru files
    Write-Verbose "Processing API endpoints..."
    $controllerStats = @{}
    $totalEndpoints = 0
    
    # Pass 1: Collect all endpoints and compute initial filenames
    $endpointList = @()
    foreach ($pathKey in $swaggerContent.paths.PSObject.Properties.Name) {
        $pathObj = $swaggerContent.paths.$pathKey
        
        foreach ($methodKey in $pathObj.PSObject.Properties.Name) {
            if ($methodKey -in @('get', 'post', 'put', 'delete', 'patch', 'options', 'head')) {
                $operation = $pathObj.$methodKey
                $controllerName = Get-ControllerName -Path $pathKey -Tags $operation.tags -OperationId $operation.operationId
                $displayName = Get-BrunoDisplayName -Method $methodKey -Path $pathKey -OperationId $operation.operationId -Summary $operation.summary
                $fileSlug = Get-BrunoFileSlug -Method $methodKey -Path $pathKey -OperationId $operation.operationId -Summary $operation.summary
                
                $endpointList += @{
                    PathKey        = $pathKey
                    MethodKey      = $methodKey
                    Operation      = $operation
                    ControllerName = $controllerName
                    DisplayName    = $displayName
                    FileSlug       = $fileSlug
                }
            }
        }
    }
    
    # Pass 2: Detect duplicate display names or filename slugs within each controller and disambiguate
    $controllerFiles = @{}
    foreach ($ep in $endpointList) {
        $key = $ep.ControllerName
        if (-not $controllerFiles.ContainsKey($key)) { $controllerFiles[$key] = @() }
        $controllerFiles[$key] += $ep
    }
    foreach ($ctrlName in $controllerFiles.Keys) {
        $eps = $controllerFiles[$ctrlName]
        $nameGroups = @(
            $eps | Group-Object { $_.DisplayName }
            $eps | Group-Object { $_.FileSlug }
        )

        foreach ($group in $nameGroups) {
            if ($group.Count -gt 1) {
                foreach ($ep in $group.Group) {
                    $ep.DisplayName = Add-MethodPrefixToDisplayName -Method $ep.MethodKey -DisplayName $ep.DisplayName
                    $ep.FileSlug = Add-MethodPrefixToSlug -Method $ep.MethodKey -Slug $ep.FileSlug
                }
            }
        }

        $displayGroups = $eps | Group-Object { $_.DisplayName }
        foreach ($group in $displayGroups) {
            if ($group.Count -gt 1) {
                foreach ($ep in $group.Group) {
                    $ep.DisplayName = Add-PathQualifierToDisplayName -DisplayName $ep.DisplayName -Path $ep.PathKey
                }
            }
        }

        $slugGroups = $eps | Group-Object { $_.FileSlug }
        foreach ($group in $slugGroups) {
            if ($group.Count -gt 1) {
                foreach ($ep in $group.Group) {
                    $ep.FileSlug = Add-PathQualifierToSlug -Slug $ep.FileSlug -Path $ep.PathKey
                }
            }
        }
    }
    
    # Pass 3: Generate directories and .bru files
    foreach ($ep in $endpointList) {
        $totalEndpoints++
        $controllerName = $ep.ControllerName
        $controllerPath = Join-Path $collectionPath $controllerName
        
        if (!(Test-Path $controllerPath)) {
            New-Item -Path $controllerPath -ItemType Directory -Force | Out-Null
            $folderBruPath = Join-Path $controllerPath "folder.bru"
            New-BrunoFolderFile -FolderName $controllerName -FilePath $folderBruPath
            $controllerStats[$controllerName] = 0
        }
        $controllerStats[$controllerName]++
        
        $displayName = $ep.DisplayName
        $fileSlug = $ep.FileSlug
        $bruFilePath = Join-Path $controllerPath "$fileSlug.bru"
        
        if (Test-Path $bruFilePath) { $filesOverwritten++ } else { $filesCreated++ }
        
        # Parse parameters
        $parameters = @{
            'path'   = @()
            'query'  = @()
            'header' = @()
        }
        
        if ($ep.Operation.parameters) {
            foreach ($param in $ep.Operation.parameters) {
                if ($param.in -in @('path', 'query', 'header')) {
                    $parameters[$param.in] += $param
                }
            }
        }
        
        # Create the .bru file
        New-BrunoApiFile -Method $ep.MethodKey -Path $ep.PathKey -DisplayName $displayName -Description $ep.Operation.description -Parameters $parameters -RequestBody $ep.Operation.requestBody -SwaggerContent $swaggerContent -FilePath $bruFilePath
        
        Write-Verbose "  ✓ Created $controllerName/$fileSlug.bru ($displayName)"
    }
    
    # Create collection configuration file
    $collectionConfig = @"
{
  "version": "1",
  "name": "$collectionName",
  "type": "collection",
  "ignore": [
    "node_modules",
    ".git"
  ]
}
"@
    
    $configPath = Join-Path $collectionPath "bruno.json"
    $collectionConfig | Out-File -FilePath $configPath -Encoding UTF8
    
    # Summary (always shown)
    Write-Success "`n🎉 Bruno collection created successfully!"
    Write-Host "📊 Summary:"
    Write-Host "   Collection: $collectionName"
    Write-Host "   Location: $collectionPath"
    Write-Host "   Environments: $($Environments.Count) ($($Environments -join ', '))"
    Write-Host "   Controllers: $($controllerStats.Count)"
    Write-Host "   Total Endpoints: $totalEndpoints"
    if ($isRegeneration) {
        Write-Host "   Files Created: $filesCreated | Files Overwritten: $filesOverwritten"
    }
    
    Write-Host "`n📁 Controller breakdown:"
    foreach ($controller in $controllerStats.GetEnumerator() | Sort-Object Name) {
        Write-Host "   $($controller.Name): $($controller.Value) endpoints"
    }
    
    Write-Host "`n🎯 Next steps:"
    Write-Host "   1. Open Bruno and select 'Open Collection'"
    Write-Host "   2. Navigate to: $collectionPath"
    Write-Host "   3. Configure environment variables as needed"
    Write-Host "   4. Review and test the generated API calls"
    Write-Host "   5. Commit to your repository following your organization's guidelines"
    
}
catch {
    Write-Error "❌ An error occurred: $($_.Exception.Message)"
    Write-Error $_.Exception.StackTrace
    exit 1
}

#endregion