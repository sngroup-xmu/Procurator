# 7 Implementation

We implement a prototype of Procurator that follows the three core designs described in our paper: (i) a **Unified Intent Language** for specifying distributed verification tasks, (ii) a **Semantic Translation Model** that realizes the actor-and-CSP semantics as a verifiable model, and (iii) a **Semantic-Aware State Pruner** that aggressively reduces irrelevant program state while preserving soundness under the chosen abstraction.

Our implementation is split between a Python front-end in `dslc/` and a p4c-based C++ backend in `P4B-Translator/backends/verify/`. Excluding vendored upstream dependencies (e.g., Ultimate and the upstream p4c front-end), the prototype contains approximately **15 KLoC of C++** (translation + pruning passes) and **14 KLoC of Python** (DSL compilation, harness generation, and toolchain orchestration), with an additional regression suite under `dslc/tests/`. These numbers are approximate and intended only to convey relative engineering effort across components.

At a high level, Procurator compiles a `*.prop` specification into a system-level Boogie model and discharges safety properties with Ultimate:

`*.prop` spec → per-node P4 translation → distributed harness composition → Ultimate/GemCutter → log + witness (if UNSAFE).

All user-facing workflows are exposed through a single CLI entrypoint, `./bin/procurator`, which by default materializes each run into a fresh directory under `.tmp/procurator/…` for reproducibility and auditing.

## 7.1 Unified Intent Language

Procurator’s Unified Intent Language provides a single place to describe both **what** to verify and **how the distributed system is wired**. A specification can (1) import P4 programs (plus control-plane entries) as node instances, (2) declare topology links between nodes, (3) describe environment/host behavior and input constraints, and (4) state safety properties as assertions over node-local or cross-node state.

We implement the front-end using the Lark parsing toolkit (`dslc/speclang/`). The parser produces a typed, structured representation of the specification that is consumed uniformly by later stages: it drives harness generation (e.g., which actors exist and which links connect them) and also provides the information needed by optimization passes (e.g., which variables are referenced by the property, hence should be preserved by pruning). This design keeps intent independent from any specific backend: the same intent representation can be lowered to different verification IRs, although our current prototype primarily targets Boogie/Ultimate for safety verification.

## 7.2 Semantic Translation Model (Actor + CSP)

The Semantic Translation Model realizes the paper’s actor-and-CSP execution model by separating translation into two layers: a **per-node compiler** for P4 semantics, and a **system-level harness generator** for distributed scheduling and communication.

### Per-node translation (P4 → Boogie)

For each imported P4 program, Procurator invokes a custom p4c backend (`p4c-translator`) implemented under `P4B-Translator/backends/verify/`. The backend uses p4c’s front-end for parsing and typechecking, then lowers the ingress/egress pipeline into a Boogie procedure that models a single **run-to-completion pass**. The translation makes state explicit: packet header fields, metadata, and stateful objects (e.g., registers) are compiled into Boogie globals and procedures so that updates become first-class transitions in the verification model. Control-plane configuration is integrated by translating BMv2-style command files into Boogie constraints and action-selection logic, ensuring the model matches a concrete deployment.

### System-level composition (Distributed harness)

To capture interactive behaviors, the compiler synthesizes a distributed Boogie harness (`dslc/backends/boogie_*`) that treats each node as a long-running actor repeatedly triggered by incoming packets. Actor interactions are encoded as message passing along topology links, matching the CSP abstraction in the paper. Concretely, the harness provides (i) an execution loop, (ii) a scheduling policy that selects the next enabled actor step, and (iii) link procedures that transfer on-wire packet state from a sender to a receiver.

We provide two equivalent harness encodings: a sequential driver (useful for debugging and proof-oriented tasks) and a concurrent encoding that explicitly forks actor threads but enforces pass-atomicity with a global lock. Both encodings preserve the key intent: **interleavings occur only at pass boundaries**, not within a pipeline pass, allowing the verifier to focus on distributed interaction patterns rather than instruction-level scheduling.

Communication uses a bounded Bag(K) abstraction controlled by the spec’s queue capacity: each actor maintains an `inbox_count` and a mailbox storing packet contents, which over-approximates nondeterministic dequeue order while bounding resource usage. For common small capacities, we additionally support a two-slot mailbox encoding to reduce spurious overwrites without abandoning the compact model.

## 7.3 Semantic-Aware State Pruner

The Semantic-Aware State Pruner implements the paper’s pruning strategy as a conservative backward slice that eliminates program fragments irrelevant to the verification intent. In our prototype, pruning is realized across two cooperating stages.

First, the P4 translation backend implements an IR-level backward slicer (`P4B-Translator/backends/verify/slicing/`). Given a set of slicing seeds, the slicer builds control/data dependence information and computes a backward slice over the P4 IR. The slice result determines which statements, variables, and tables are retained during translation. Importantly, the slicer also derives register-index bounds for stateful arrays; when only a small set of indices is relevant to the property, the backend emits corresponding Boogie assumptions to constrain index domains, substantially reducing the SMT burden of array reasoning.

Second, because slicing is computed per node, the DSL compiler performs a system-level seed planning step. It derives property-driven seeds from the Unified Intent Language and conservatively propagates **on-wire header dependencies** along topology links so that upstream actors retain the packet fields required by downstream computations. The compiler also prunes environment injections and nondeterministic inputs to those that remain live after slicing, avoiding both unnecessary nondeterminism and post-slice typechecking failures.

Beyond slicing, the harness layer provides additional sound reductions that are naturally expressible at the system level: conservative pass-boundary partial-order reduction (POR) and symmetry constraints for symmetric deployments. These reductions trade completeness only with respect to the chosen abstraction (e.g., Bag(K) message model) while preserving soundness for UNSAFE results.

## 7.4 Backend Integration and Regression Checks

We integrate Ultimate through a thin runner in `dslc/toolchain/` that selects toolchain/setting presets, isolates per-run working directories, and collects solver logs and GraphML witnesses. For debugging and long-running experiments, the witness utilities support extracting the concrete assumptions used by Ultimate, enabling deterministic reruns and minimizing “one-off” counterexamples.

To prevent regressions in the semantic translation and pruning pipeline, we maintain a growing regression suite under `dslc/tests/`. In addition, the translator exposes slicing selftests that assert key slicing invariants on representative P4 programs; these selftests are executed from the Python regression suite to catch unsound pruning early.
