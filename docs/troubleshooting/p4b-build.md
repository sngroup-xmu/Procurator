# p4c Translator Build

On Ubuntu, install the native build dependencies before configuring P4B:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget unzip \
  python3 python3-venv \
  build-essential cmake pkg-config bison flex libfl-dev \
  libgc-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev
```

Build `p4c-translator` from `src/p4b/source/build-host` with:

```bash
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```
