# Feature Specification: Bruno Scaffolder

**Feature Branch**: `001-bruno-scaffolder`  
**Created**: 2026-03-06  
**Status**: Draft  
**Input**: User description: "Create a Bruno scaffolder that takes swagger.json as input and generates Bruno API collection structure for source control, following the documented process, PowerShell best practices, and industry standards. Developer and tester friendly. Not overkill."

## Clarifications

### Session 2026-03-18

- Q: Will the `bruno/` folder under a project ever contain multiple collection folders, or should it be treated as a single-collection location for one API project? → A: Treat it as a single-collection location for one API project. The collection name exists primarily to identify the collection inside the Bruno client and on disk, not to support multiple sibling collections under one API project's `bruno/` folder. In a monorepo, each API project should own its own local `bruno/` directory.
- Q: Should generated request names shown in Bruno match the on-disk `.bru` filename exactly, or should Bruno optimize for readability while filenames optimize for stable source control naming? → A: Separate them. Bruno request display names should be human-readable Title Case labels, while `.bru` filenames should be stable lowercase kebab-case slugs. HTTP method prefixes should be added only when needed to disambiguate collisions within the same controller folder.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Generate a Bruno collection from swagger.json (Priority: P1)

A developer or tester has an OpenAPI 3.0+ JSON file for their API. They run the scaffolder script, providing the swagger file path and an API name. The scaffolder reads the contract, creates the standard folder structure (collection folder, environments, controller folders, `.bru` request files), and outputs a ready-to-use Bruno collection that can be opened in Bruno and committed to source control.

**Why this priority**: This is the core value proposition — eliminating manual `.bru` file creation and ensuring every team gets a consistent, contract-aligned collection from a single command.

**Independent Test**: Can be fully tested by running the script against a sample swagger.json and verifying the output folder structure matches the documented process conventions. The generated collection can be opened in Bruno and each request exercised.

**Acceptance Scenarios**:

1. **Given** a valid OpenAPI 3.0+ JSON file and an API name, **When** the user runs the scaffolder for an API project, **Then** that API project's local `bruno/` location contains a single generated collection structure with `bruno.json`, an `environments/` directory with default environment files, and controller folders with `.bru` files for each endpoint.
2. **Given** the generated collection, **When** the user opens it in Bruno, **Then** all endpoints, parameters, headers, and request bodies are populated correctly and environments are selectable.
3. **Given** the generated collection, **When** the user opens it in Bruno, **Then** each request is shown with a human-readable display name rather than a raw filename slug.
4. **Given** a swagger file with multiple tags/controllers, **When** the scaffolder runs, **Then** endpoints are grouped into folders matching their controller/tag names using PascalCase.
5. **Given** endpoints with path parameters, query parameters, and headers, **When** the scaffolder generates `.bru` files, **Then** each parameter type is correctly placed in the appropriate Bruno section with placeholder values.
6. **Given** POST/PUT/PATCH endpoints with request bodies defined via JSON schema, **When** the scaffolder generates `.bru` files, **Then** the body section contains a JSON template derived from the schema with placeholder values.

---

### User Story 2 - Customize organization defaults via configuration (Priority: P2)

A team lead wants to set their company name, standard environments, and base URL patterns once so every developer generates collections with the same organizational defaults without passing extra flags.

**Why this priority**: Consistency across teams depends on shared defaults. Without this, every invocation risks drift from the organizational standard.

**Independent Test**: Can be fully tested by editing the configuration file, running the scaffolder with only required parameters, and confirming the output reflects the configured defaults.

**Acceptance Scenarios**:

1. **Given** a configuration file with a custom company name and environment list, **When** the scaffolder runs without explicit `-CompanyName` or `-Environments` flags, **Then** the output uses the values from the configuration file.
2. **Given** command-line parameters that override configuration defaults, **When** the scaffolder runs, **Then** command-line values take precedence over the configuration file.
3. **Given** no configuration file exists, **When** the scaffolder runs, **Then** sensible built-in defaults are used and the user is informed.

---

### User Story 3 - Regenerate collection when API evolves (Priority: P3)

An API has changed (new endpoints, removed endpoints, updated parameters). A developer re-exports the swagger.json and reruns the scaffolder against the same output path. The scaffolder refreshes the collection to reflect the current contract.

**Why this priority**: APIs evolve continuously. The scaffolder must support regeneration so collections stay aligned with the contract without requiring manual diffing.

**Independent Test**: Can be fully tested by generating a collection, modifying the swagger file (add/remove an endpoint), rerunning the scaffolder, and confirming the output matches the updated contract.

**Acceptance Scenarios**:

1. **Given** an existing collection directory and an updated swagger file, **When** the scaffolder runs targeting the same output path, **Then** the collection is updated to reflect the current swagger without corrupting existing structure.
2. **Given** a regeneration, **When** the process completes, **Then** the user is informed that the directory already existed and contents were merged/overwritten.

---

### Edge Cases

- What happens when the swagger file is not valid JSON? The scaffolder MUST exit with a clear, actionable error message.
- What happens when the swagger file contains no paths? The scaffolder MUST create the collection skeleton (environments, bruno.json) and warn that no endpoints were found.
- What happens when an endpoint has no tags and no operationId? The scaffolder MUST fall back to deriving the controller and file name from the URL path segments.
- What happens when two endpoints would produce the same `.bru` filename within the same controller folder? The scaffolder MUST produce distinct filenames (e.g., by incorporating the HTTP method).
- What happens when an endpoint does not provide a usable summary? The scaffolder MUST derive a readable request display name from the operationId when available, otherwise from the HTTP method and URL path.
- What happens when two endpoints would produce the same readable request name or `.bru` filename within the same controller folder? The scaffolder MUST produce distinct outputs, preferring HTTP method prefixes only when needed to disambiguate collisions.
- What happens when a request body schema is a top-level array of objects? The scaffolder MUST generate a `body:json` template that remains an array in the `.bru` output rather than collapsing to a single object.
- What happens when the user passes an output path they cannot write to? The scaffolder MUST fail with a permission error rather than silently producing partial output.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The scaffolder MUST accept a path to an OpenAPI 3.0+ JSON file and an API name as required inputs.
- **FR-002**: The scaffolder MUST generate the standard collection structure as documented in the Bruno Collection Process: a single collection root inside the API project's local `bruno/` directory containing `bruno.json`, `environments/` with default environment `.bru` files, and controller folders containing individual `.bru` request files.
- **FR-003**: The scaffolder MUST group endpoints into controller folders based on swagger tags; when tags are absent, it MUST derive grouping from the URL path or operationId.
- **FR-004**: The scaffolder MUST generate `.bru` files that include the correct HTTP method, URL with `{{baseUrl}}` variable prefix, path parameters as Bruno variables, query parameters, headers, and JSON request bodies where applicable.
- **FR-005**: The scaffolder MUST create environment files for each configured environment, each containing at minimum a `baseUrl` variable and an empty `vars:secret` section.
- **FR-006**: The scaffolder MUST load organizational defaults (company name, environments, base URL patterns) from an external configuration file, with command-line parameters taking precedence.
- **FR-007**: The scaffolder MUST NOT embed any real secrets, API keys, passwords, or sensitive values in generated files; all sensitive fields MUST use placeholder or secret-designated variables.
- **FR-008**: The scaffolder MUST produce clear, actionable error messages when given invalid input (missing file, malformed JSON, no paths in swagger).
- **FR-009**: The scaffolder MUST generate a `folder.bru` metadata file inside each controller folder.
- **FR-010**: The scaffolder MUST support a verbose mode that provides detailed progress output for troubleshooting.
- **FR-011**: The scaffolder MUST generate request display names for Bruno separately from on-disk `.bru` filenames.
- **FR-012**: The scaffolder MUST prefer OpenAPI `summary` values as the source for Bruno request display names when they are present and usable, falling back to operationId and then to method-plus-path derivation.
- **FR-013**: The scaffolder MUST render Bruno request display names as human-readable Title Case labels with spaces between words.
- **FR-014**: The scaffolder MUST generate on-disk `.bru` filenames as stable lowercase kebab-case slugs suitable for source control.
- **FR-015**: The scaffolder MUST add HTTP method prefixes to request display names and `.bru` filenames only when needed to disambiguate collisions within the same controller folder.
- **FR-016**: The scaffolder MUST resolve request body schemas that use `$ref` references, including nested object references, to produce meaningful JSON body templates in generated `.bru` files.
- **FR-017**: The scaffolder MUST support common composed request body schemas used in OpenAPI contracts, including `allOf`, and MUST generate a representative JSON template when such schemas are present.
- **FR-018**: The scaffolder MUST preserve top-level array request bodies in generated `body:json` sections so endpoints that accept list input produce JSON arrays rather than single objects.
- **FR-019**: The scaffolder examples and documentation MUST designate one repository-owned sample contract as the canonical regression sample for scaffolder-specific edge cases.
- **FR-020**: When additional public or widely recognized sample contracts are included for compatibility testing, the scaffolder examples and documentation MUST identify them as secondary smoke-test inputs rather than the canonical reference sample.
- **FR-021**: The scaffolder and its documentation MUST assume a single Bruno collection per API project `bruno/` location rather than a multi-collection layout under the same project folder.
- **FR-022**: The generated collection metadata name MUST be treated as the primary identifier shown within the Bruno client, rather than as a mechanism for supporting multiple sibling collection folders under one API project's `bruno/` location.
- **FR-023**: In monorepos, the scaffolder process and documentation MUST treat each API project as owning its own local `bruno/` directory rather than using a single shared repository-level `bruno/` folder for multiple APIs.

### Key Entities

- **OpenAPI Specification**: The input contract file; contains paths, operations, parameters, schemas, and server definitions.
- **Bruno Collection**: The output artifact; a single collection root inside an API project's local `bruno/` directory containing `bruno.json`, environment files, and `.bru` request files organized by controller.
- **Scaffolder Configuration**: An external JSON file holding organizational defaults (company name, environments, base URL patterns).
- **Environment File**: A `.bru` file under `environments/` defining variables (e.g., `baseUrl`) and a secret section for each deployment target.
- **Controller Folder**: A directory within the collection grouping related endpoints, named after the swagger tag or derived from the URL path.
- **Request Display Name**: The human-readable request label shown inside Bruno, derived from summary, operationId, or method/path fallback and formatted for readability.
- **Request File Slug**: The stable lowercase kebab-case basename used for the `.bru` file on disk.
- **Canonical Regression Sample**: A repository-owned example OpenAPI file intentionally shaped to cover scaffolder-specific edge cases and serve as the primary checked-in reference for verification.
- **Compatibility Sample**: A public or widely recognized OpenAPI example kept for broader smoke testing, but not treated as the canonical regression reference.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: A developer can generate a complete, Bruno-openable collection from a valid OpenAPI 3.0+ JSON file in a single command invocation.
- **SC-002**: The generated collection structure matches the documented Bruno Collection Process conventions exactly (folder hierarchy, naming, environment files).
- **SC-003**: 100% of endpoints defined in the swagger file produce corresponding `.bru` files with correct HTTP method, URL, and parameter placement.
- **SC-004**: No generated file contains any real secret or credential; all sensitive fields use placeholders or secret-designated sections.
- **SC-005**: Invalid inputs (missing file, bad JSON, empty paths) produce user-facing error messages that identify the problem and suggest corrective action.
- **SC-006**: The scaffolder runs successfully on PowerShell 5.1+ without requiring external modules or dependencies beyond the standard library.
- **SC-007**: Team members unfamiliar with the scaffolder can generate their first collection within 5 minutes by following the README quick start instructions.
- **SC-008**: Endpoints whose request bodies are defined as top-level arrays generate `.bru` request bodies that remain wrapped in `[]` in the output.
- **SC-009**: The examples documentation clearly explains which sample contract is the canonical regression reference and which sample contracts are included only for broader compatibility testing.
- **SC-010**: Generated request names shown in Bruno are readable to developers and testers without requiring them to parse camel case, collapsed operationIds, or raw path-derived slugs.
- **SC-011**: Regenerating the same OpenAPI document produces the same `.bru` filenames unless the underlying endpoint naming inputs change or a collision requires deterministic disambiguation.
