# Feature Specification: Bruno Request Prompt

**Feature Branch**: `[002-add-bruno-prompt]`  
**Created**: 2026-03-18  
**Status**: Ready for Source Control  
**Input**: User description: "i want to add a prompt to this project for bruno. The idea is that users can now simply add the prompt along with maybe the name of the API they just created such that the manual process of creating a new request in the bruno folder structure can be done by copilot/agent. The assumption here is that the project has either already ran the scaffolder or did the process manually and is following the bruno process mentioned such that whenever a new API is created they are adding the request in bruno and is sending that files as well in the PR. I want to provide a context aware prompt and references to be attached ot the prompt such that a developer working on a new API dont have to create the request manually and can simply copy paste the prompt and it will create the bru file for them after analysing the controller method."

## User Scenarios & Testing _(mandatory)_

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Generate Bruno Request From Prompt (Priority: P1)

As a developer creating a new API endpoint, I can paste a project-provided prompt and provide endpoint context (endpoint reference and optional collection confirmation), so that a valid new Bruno request file is produced in the correct folder without manual file authoring.

**Why this priority**: This is the core value proposition of the feature and removes the most time-consuming, repetitive manual work from the endpoint development workflow.

**Independent Test**: Can be fully tested by creating a sample new endpoint, running the prompt workflow once, and verifying that one new request file is generated in the correct location with required request metadata.

**Acceptance Scenarios**:

1. **Given** a repository that already follows the Bruno folder process, **When** a developer runs the prompt with a new endpoint's context, **Then** the process produces a new request file in the expected Bruno subfolder.
2. **Given** a controller method with route and HTTP verb details, **When** the prompt is used, **Then** the generated request content reflects the endpoint method, route, and expected request structure.
3. **Given** a developer provides endpoint details (and optional collection name confirmation), **When** the prompt completes, **Then** the generated file uses consistent naming conventions aligned with existing Bruno artifacts.

---

### User Story 2 - Context-Aware Prompt Guidance (Priority: P2)

As a developer, I can access a prompt that uses only the Bruno assets already in my repository (after initial scaffolder setup), so that I do not need external process documents or manual convention guessing when generating a new request file.

**Why this priority**: Prompt quality depends on grounded project context; this reduces generation errors and rework.

**Independent Test**: Can be independently tested by reviewing the prompt package and confirming it uses only in-repository Bruno artifacts as context, then validating output quality on at least one endpoint.

**Acceptance Scenarios**:

1. **Given** the prompt is opened by a developer unfamiliar with the Bruno process, **When** they execute it with minimal inputs, **Then** it derives request details from source and from existing Bruno folder structure in the same repository.
2. **Given** the repository already contains scaffolded Bruno assets, **When** output is generated, **Then** the output aligns with existing repository conventions for foldering and request composition without requiring external documentation imports.

---

### User Story 3 - PR-Ready API Request Artifacts (Priority: P3)

As a reviewer or contributor, I receive Bruno request artifacts for newly added APIs in the same pull request as the endpoint code, so that API testability and collaboration readiness are maintained.

**Why this priority**: This supports team workflow consistency and reduces follow-up requests during code review.

**Independent Test**: Can be tested by validating that a PR containing a new endpoint also contains its generated Bruno request artifact and passes repository review expectations.

**Acceptance Scenarios**:

1. **Given** a developer adds a new API endpoint, **When** they use the prompt workflow, **Then** a corresponding Bruno request artifact is created and can be included in the same PR.
2. **Given** a reviewer checks a PR for a new endpoint, **When** the generated Bruno request is present, **Then** the reviewer can validate endpoint behavior expectations without requesting manual request-file follow-up.

---

### Edge Cases

- The developer provides an API/controller reference that cannot be found in the workspace.
- The controller method exists but omits required request details (for example, ambiguous route or payload expectations).
- A matching Bruno folder for the API does not yet exist even though the project otherwise follows the Bruno process.
- The project `bruno/` folder contains zero collection folders.
- The project `bruno/` folder contains multiple sibling collection folders and the target cannot be inferred unambiguously.
- A request file for the same endpoint already exists and a duplicate would be created.
- The developer provides incomplete prompt input (for example, endpoint method context is missing or invalid).

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The project MUST provide a reusable prompt artifact that instructs a developer how to generate a new Bruno request for a newly created API endpoint.
- **FR-002**: The prompt MUST accept minimal endpoint context input from the developer (`endpointReference` required, `collectionName` optional confirmation), and SHOULD derive HTTP method, route, parameters, and body shape from source whenever possible.
- **FR-003**: The prompt workflow MUST direct generation of exactly one Bruno request file per specified endpoint execution, unless the endpoint already has an existing request artifact.
- **FR-004**: Generated Bruno request artifacts MUST follow the repository's established Bruno folder and naming conventions used by existing collections.
- **FR-005**: The prompt workflow MUST rely on in-repository Bruno artifacts (existing collection structure, sibling requests, and environment files) as primary context after initial scaffolder/manual setup, without requiring developers to import external process documents.
- **FR-006**: The workflow MUST instruct the developer to include the generated Bruno request artifact in the same pull request as the new API endpoint changes.
- **FR-007**: If required endpoint context is missing or cannot be resolved from provided references, the workflow MUST return a clear, actionable message describing what information is needed before generation can continue.
- **FR-008**: If a request artifact for the specified endpoint already exists, the workflow MUST prevent silent duplication and require explicit developer choice to update or create a distinct artifact.
- **FR-009**: If the target Bruno collection or controller folder is missing, the workflow MUST not continue silently and MUST provide explicit create-or-correct instructions before request generation proceeds.
- **FR-010**: The workflow MUST enforce the one-API-project-to-one-collection standard by failing fast when `bruno/` contains zero or multiple collection folders, with actionable guidance.
- **FR-011**: The workflow MUST apply a bounded context strategy for large collections by preferring structure-first discovery and limiting `.bru` content sampling (max 3 files and max 400 lines) before requesting clarification.

### Key Entities _(include if feature involves data)_

- **Prompt Artifact**: The reusable instruction content developers copy/use to trigger request generation; includes expected inputs, references, and output expectations.
- **Endpoint Context**: The developer-supplied or workspace-derived API details needed to generate a request artifact, such as endpoint reference, optional collection name confirmation, controller method, route, and operation intent.
- **Bruno Request Artifact**: The generated request file representing one API operation and intended to reside in the established Bruno collection structure.
- **Bruno In-Repo Context**: Existing Bruno collection structure, sibling requests, and environment files that define practical formatting, naming, and placement rules within the developer's repository.

## Assumptions

- The repository already contains a valid Bruno collection structure, produced either through the existing scaffolder or through compliant manual setup.
- The repository follows the standard mapping of one API project to one Bruno collection under that project's `bruno/` folder.
- The initial scaffolder/manual setup is a one-time bootstrap step; prompt-based generation is for incremental new endpoint requests after that baseline exists.
- Developers invoking the prompt have already implemented or are actively implementing the corresponding API endpoint.
- Developers provide minimal endpoint context (`endpointReference`), and only provide `collectionName` as optional confirmation when source-derived inference is ambiguous.
- Repository reviewers expect Bruno request artifacts to be present for newly added endpoints.

## Findings (2026-03-18)

- Running scaffolder with an unrelated Swagger input can generate methods (for example PUT) that are not present in the target controller source; this is expected contract-driven behavior.
- For prompt usability, developers should not provide HTTP method/route/query/header/body manually; these should be source-derived from the referenced .NET controller method.
- External process-reference attachment is impractical for consumer repos that only contain the generated `bruno/` folder; prompt guidance must be self-sufficient within the target repo.

## Finalized Design Decisions (2026-03-18)

- Input naming is standardized on `endpointReference` (required) and `collectionName` (optional confirmation); `apiName` is no longer used by the prompt workflow.
- The one-collection-per-API-project rule is enforced in the prompt flow: generation stops when `bruno/` contains zero or multiple collection folders.
- Prompt execution uses bounded context-budget behavior for scale: structure-first scan, sample at most 3 `.bru` files, and cap `.bru` context at 400 lines before escalating ambiguity.
- The sample harness was renamed from `examples/dotnet-api-prompt-sample` to `examples/dotnet-api-sample`; project naming is prompt-neutral while README guidance explicitly covers both scaffolder and prompt testing.
- Sample runtime documentation avoids fixed localhost ports and uses `<base-url>/swagger` from terminal output to avoid non-deterministic port assumptions.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: At least 90% of first-attempt prompt runs for new endpoints produce a Bruno request artifact that needs no structural corrections before PR submission.
- **SC-002**: Developers can complete the request-artifact generation workflow in under 5 minutes for a standard new endpoint.
- **SC-003**: For new endpoint PRs that use this workflow, at least 95% include a corresponding Bruno request artifact on first review cycle.
- **SC-004**: Team-reported manual effort for creating Bruno request files for new endpoints decreases by at least 60% within one release cycle after adoption.
