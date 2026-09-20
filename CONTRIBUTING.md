# Contributing

## Development setup

1. Install Aftman and run `aftman install` from the repository root.
2. Use the **Format check**, **Lint**, **Build example**, and **Build package** VS Code tasks before opening a pull request.
3. Keep the public API and its generic example synchronized.

## Scope

This repository currently owns a static Luau typing contract. Do not describe or imply runtime loading, lifecycle execution, networking, client asset exposure, or runtime dependency resolution unless that behavior is implemented and validated here. Keep client asset exposure as an optional feature Bundle concern rather than adding it to the core contract.

## Pull requests

- Format changed Luau with StyLua.
- Run Selene and build both the example and package Rojo projects.
- Add or update generic examples when changing the API contract.
- Document durable public API decisions in `.ai/decision/` when the repository workflow applies.