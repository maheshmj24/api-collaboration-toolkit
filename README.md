# API Collaboration Toolkit

## Overview

This repository contains tooling and guidance for creating source-controlled API collaboration assets from API contracts.

The goal is to eliminate API information silos and enable seamless collaboration across development, testing, and security review teams through standardized tooling and processes.

The current implementation focus is a Bruno collaboration workflow that combines:

- scaffolder-driven baseline collection generation from OpenAPI contracts
- prompt-driven incremental request generation for newly added endpoints

## Vision

Eliminate API information silos and enable seamless collaboration across development, testing, and security review teams through standardized tooling and processes.

## Mission

Establish a standardized process for maintaining API request collections as living documentation alongside codebases. The scaffolder accelerates baseline adoption from OpenAPI specifications, and the prompt workflow accelerates incremental endpoint request authoring.

## Objectives

- Standardize API collaboration by defining a repeatable workflow where API collections are maintained as part of normal development rather than as an afterthought.
- Accelerate onboarding by generating initial API request collections from OpenAPI specs so teams start with usable artifacts instead of building collections from scratch.
- Break down information silos by ensuring up-to-date, executable API collections are maintained by the team and stored with the codebase.
- Accelerate bug fixes and feature work by giving developers immediate API context when working in existing systems.
- Enable security and QA teams with executable API requests instead of static documents or incomplete hand-maintained collections.
- Reduce development friction by eliminating the need to hunt down original developers or recreate API requests manually.

The current focus is Bruno-based collaboration:

- process guidance for how Bruno collections should be organized and maintained
- a PowerShell scaffolder that generates Bruno collections from OpenAPI 3.0+ JSON files
- a reusable prompt workflow for generating one new `.bru` request artifact from endpoint source context
- example contracts and generated output for validation and onboarding

## Repository Structure

```text
bruno/
├── process/
│   └── PROCESS.md
├── prompts/
│   ├── bruno-request-generator.prompt.md
│   └── README.md
└── scaffolder/
    ├── Generate-BrunoCollection.ps1
    ├── bruno-scaffolder-config.json
    ├── README.md
    └── examples/

examples/
├── api-collaboration-toolkit.sln
└── dotnet-api-sample/
    └── README.md
```

## Start Here

If you want to understand the expected Bruno collection structure and team workflow, read [bruno/process/PROCESS.md](bruno/process/PROCESS.md).

If you want to generate a Bruno collection from an OpenAPI contract, read [bruno/scaffolder/README.md](bruno/scaffolder/README.md).

If you want to generate a single Bruno request file for a newly added endpoint using a prompt workflow, read [bruno/prompts/README.md](bruno/prompts/README.md).

## Current Scope

This repository currently provides:

- a documented Bruno collaboration process
- a PowerShell scaffolder for OpenAPI-to-Bruno baseline generation
- a prompt workflow for single-endpoint `.bru` generation in existing collections
- example inputs and reference outputs for verification

Current support is Bruno collection lifecycle support (baseline scaffolding + incremental prompt-assisted request generation). The toolkit is intended to expand to additional API clients over time, but Bruno is the current supported client workflow.

## Intended Audience

This repository is for engineers who:

- need a consistent way to store API collaboration artifacts in source control
- want to generate Bruno collections from API contracts rather than maintain them manually
- want to generate new endpoint request artifacts incrementally using prompt/agent workflow
- need examples and process guidance for onboarding or review

## Contributing

This project is for contributors who want to improve API collaboration in a concrete way. If you have a specific idea, gap, or improvement in mind and are prepared to help drive it through design, implementation, and validation, your contribution is welcome.

Good contributions typically include:

- a clearly stated problem or improvement opportunity
- a practical proposal for how to address it
- execution through code, documentation, examples, or validation

Areas where contributors can add value include:

- extending the toolkit to additional API clients over time
- expanding OpenAPI request and schema support
- improving request generation quality and edge-case handling
- refining best practices for collection maintenance in source control

The project is best suited to contributors who want to identify concrete improvements and help carry them through.

When changing scaffolder behavior or collection conventions:

- update the relevant docs and examples
- keep generated artifacts safe for source control
- preserve contract alignment between the OpenAPI input and generated Bruno output

## Related Documentation

- [bruno/process/PROCESS.md](bruno/process/PROCESS.md)
- [bruno/scaffolder/README.md](bruno/scaffolder/README.md)
- [bruno/scaffolder/examples/README.md](bruno/scaffolder/examples/README.md)
- [bruno/prompts/README.md](bruno/prompts/README.md)
- [examples/dotnet-api-sample/README.md](examples/dotnet-api-sample/README.md)
