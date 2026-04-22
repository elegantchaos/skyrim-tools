## Project Specific Rules

- This repository contains a Swift command-line tool and supporting library code for generating, merging, and transforming Skyrim mod configuration, manifest, and model files.

## Standard Rules

- Keep changes small, targeted, and consistent with the existing Swift package and target boundaries.
- Apply DRY and single-source-of-truth first; prefer KISS, YAGNI, composition, dependency injection, command-query separation, design by contract, idempotency, and structured concurrency when they simplify the result.
- Inspect the relevant code and docs before editing, then add or update tests for behavior changes.
- Use red/green TDD for non-UI code.
- If UI code is added, create previews for it.
- Run the relevant validation workflow after changes and report any skipped checks or residual risks.
- Use trusted primary sources for technical decisions.
- Never expose or commit credentials or secrets.
- Do not perform irreversible destructive actions without explicit approval.
- Avoid unrelated refactors during focused tasks.
- If unexpected workspace changes appear, pause and confirm direction.

## Skills

- Use the coding-standards skill for baseline software engineering, change scope, testing strategy, and source-selection guidance.
- Use the swift skill for baseline Swift language, package, and API guidance.
- Use the swift-testing-pro skill when adding or changing tests written with Swift Testing.

To refresh this file, use the refresh-agents skill.
