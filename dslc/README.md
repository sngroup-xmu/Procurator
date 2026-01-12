# dslc

Standalone compiler for the DSL spec language (parser lives in `dslc/speclang`).

Typical usage (Boogie backend):

```
PYTHONPATH=/mnt/e/p4-verify /mnt/e/p4-verify/.venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec <spec.prop> \
  --out <out>.bpl \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-linux/backends/verify/p4c-translator \
  --boogie-harness concurrent \
  --work-dir <work_dir>
```
