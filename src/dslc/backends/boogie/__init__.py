"""Boogie backend package.

The implementation is split by ownership:
  - ``core``: Boogie text utilities and compatibility rewrites.
  - ``node``: P4B invocation, node-local metadata, slicing seeds, registers.
  - ``harness``: distributed topology, mailbox, actor schedule, and DSL logic.
  - ``compiler``: orchestration across the pieces above.

Old ``dslc.backends.boogie_*`` module names are registered as import aliases
below.  They are compatibility shims for tests and external scripts; new code
should import from this package directly.
"""

from __future__ import annotations

import sys
from importlib import import_module

from .compiler import BoogieBackend
from .core.errors import BoogieBackendError, P4BTranslatorError

__all__ = ["BoogieBackend", "BoogieBackendError", "P4BTranslatorError"]


_COMPAT_ALIASES = {
    "boogie_backend": "dslc.backends.boogie.compiler",
    "boogie_backend_merge": "dslc.backends.boogie.merge",
    "boogie_backend_profile": "dslc.backends.boogie.profile",
    "boogie_bpl": "dslc.backends.boogie.core.bpl",
    "boogie_common": "dslc.backends.boogie.core.common",
    "boogie_dsl": "dslc.backends.boogie.core.dsl",
    "boogie_errors": "dslc.backends.boogie.core.errors",
    "boogie_pipeline": "dslc.backends.boogie.core.pipeline",
    "boogie_prefix": "dslc.backends.boogie.core.prefix",
    "boogie_p4b": "dslc.backends.boogie.node.p4b",
    "boogie_registers": "dslc.backends.boogie.node.registers",
    "boogie_seeds": "dslc.backends.boogie.node.seeds",
    "boogie_harness": "dslc.backends.boogie.harness.emitter",
    "boogie_harness_render": "dslc.backends.boogie.harness.render",
    "boogie_harness_trace": "dslc.backends.boogie.harness.trace",
    "boogie_harness_types": "dslc.backends.boogie.harness.types",
    "boogie_harness_dsl": "dslc.backends.boogie.harness.flow.dsl",
    "boogie_harness_links": "dslc.backends.boogie.harness.flow.links",
    "boogie_harness_por": "dslc.backends.boogie.harness.flow.por",
    "boogie_harness_sequential": "dslc.backends.boogie.harness.flow.sequential",
    "boogie_harness_threads": "dslc.backends.boogie.harness.flow.threads",
    "boogie_harness_mailbox": "dslc.backends.boogie.harness.state.mailbox",
    "boogie_harness_registers": "dslc.backends.boogie.harness.state.registers",
    "boogie_harness_start": "dslc.backends.boogie.harness.state.start",
}


def _install_compat_aliases() -> None:
    parent = sys.modules.get("dslc.backends")
    for old_name, new_name in _COMPAT_ALIASES.items():
        module = import_module(new_name)
        legacy_name = f"dslc.backends.{old_name}"
        sys.modules.setdefault(legacy_name, module)
        if parent is not None:
            setattr(parent, old_name, module)


_install_compat_aliases()
