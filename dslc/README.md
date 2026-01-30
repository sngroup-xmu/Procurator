# dslc

Standalone compiler for the DSL spec language (parser lives in `dslc/speclang`).

Typical usage (Boogie backend; no-cache by default):

```bash
./bin/procurator compile \
  --spec <spec.prop> \
  --backend boogie \
  --out <out>.bpl \
  --work-dir <work_dir> \
  --p4b-bin P4B-Translator/build-host/p4c-translator
```
