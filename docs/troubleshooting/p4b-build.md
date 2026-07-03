# p4c Translator Build

Build `p4c-translator` from `src/p4b/source/build-host` with:

```bash
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```
