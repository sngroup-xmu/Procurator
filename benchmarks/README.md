# Benchmarks

This directory contains the public benchmark inputs for the Procurator artifact.

- `specs/`: Procurator DSL specifications.
- `datasets/`: P4 programs, table entries, and configuration files referenced
  by retained specifications.

Specifications use paths relative to their location. For example, specs under
`benchmarks/specs/bench/` refer to datasets via `../../datasets/...`.
