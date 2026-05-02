from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Dict


class BackendCompileProfile:
    def __init__(
        self,
        *,
        boogie_harness: str,
        pipeline_two_stage: bool,
        enable_slicing: bool,
        prune_env_inputs: bool,
    ) -> None:
        self._path = os.getenv("PROCURATOR_COMPILE_PROFILE_JSON", "").strip()
        self._enabled = bool(self._path)
        self._start = time.perf_counter()
        self.record: Dict[str, object] = {
            "event": "boogie_backend_compile",
            "tag": os.getenv("PROCURATOR_COMPILE_PROFILE_TAG", "").strip(),
            "boogie_harness": boogie_harness,
            "pipeline_two_stage": bool(pipeline_two_stage),
            "enable_slicing": bool(enable_slicing),
            "prune_env_inputs": bool(prune_env_inputs),
            "nodes": {},
        }

    @staticmethod
    def mark() -> float:
        return time.perf_counter()

    @staticmethod
    def elapsed_since(mark: float) -> float:
        return round(time.perf_counter() - mark, 6)

    def total_elapsed(self) -> float:
        return self.elapsed_since(self._start)

    def append(self) -> None:
        if not self._enabled:
            return
        try:
            path = Path(self._path)
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("a", encoding="utf-8") as f:
                f.write(json.dumps(self.record, sort_keys=True))
                f.write("\n")
        except Exception:
            # Profiling must never affect compilation correctness.
            pass
