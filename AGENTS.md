# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains no application code, tests, assets, or build configuration. Keep the root focused on project documentation and configuration. When implementation begins, organize source code in `src/`, automated tests in `tests/`, and static resources in `assets/`, unless the chosen framework requires a different layout. Update this guide to describe the actual structure as it develops.

## Build, Test, and Development Commands

No build, test, or local development commands are configured yet. When adding a toolchain, document its prerequisites, installation steps, and exact commands in `README.md`. Provide consistent entry points for running locally, building distributable output, and executing tests. Do not document commands such as `npm test` until the corresponding configuration exists.

## Coding Style & Naming Conventions

Follow the conventions of the language and framework introduced by the first implementation. Configure a formatter and linter early, and commit their configuration so contributors can reproduce checks locally. Use descriptive names for files, functions, and variables; keep naming and indentation consistent within each module. Avoid adding unrelated formatting changes to functional updates.

## Testing Guidelines

No testing framework or coverage threshold is currently defined. Add automated tests alongside new behavior and regression tests for bug fixes. Use descriptive test names that identify the behavior and expected result. Document the test runner and file naming pattern when selected, and run the relevant checks before submitting changes.

## Commit & Pull Request Guidelines

This directory has no Git history from which to infer commit conventions. Use concise, imperative commit subjects, such as `Add event listing view`, and keep commits focused on one change. Pull requests should explain the purpose, summarize implementation changes, link relevant issues, and describe validation performed. Include screenshots for visible interface changes and note any setup requirements.

## Security & Configuration

Never commit credentials, API keys, or private data. Keep local configuration out of version control and provide placeholder configuration examples when needed.
