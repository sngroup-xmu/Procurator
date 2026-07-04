# DSL Language

Procurator specifications live in `.prop` files. A spec imports P4 programs,
declares topology, models host or environment inputs, and states safety
assertions.

The top-level syntax tree is:

```text
spec
  import*
  topology
  node* | host*
  global
```

The grammar entry point is:

```text
start: import_section topology_section (node_section | host_section)* global_section
```

Use [../tutorial.md](../tutorial.md) for a complete walkthrough and NetChain
example.
