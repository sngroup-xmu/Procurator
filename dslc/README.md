# dslc

Standalone compiler for the DSL spec language (parser lives in `dslc/speclang`).

Typical usage (Boogie backend):

```bash
PYTHONPATH=. .venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec <spec.prop> \
  --out <out>.bpl \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --boogie-harness concurrent \
  --work-dir <work_dir>
```
