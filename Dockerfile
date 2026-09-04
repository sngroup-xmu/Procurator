# syntax=docker/dockerfile:1
# Procurator image: bundles the P4B translator (P4 -> Boogie), the pinned
# Ultimate/GemCutter solver, and all benchmark specs, so everything runs
# with docker build + docker run and no host setup.
#
# Build from the repository root:
#   docker build -t procurator .
# Run (results persist in ./ae-out/):
#   artifact/docker/run.sh verify --spec /work/<your>.prop
#   artifact/docker/run.sh ae          # full artifact evaluation (~2-4 h)

# ---------- build stage: compile p4c-translator, fetch the solver ----------
# Only the C++ source tree and the two pinned downloads live here, so edits
# to Python code or docs never invalidate the expensive compile layers.
FROM ubuntu:24.04 AS build
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip git \
    cmake build-essential pkg-config bison flex libfl-dev \
    libgc-dev libgmp-dev \
    libboost-dev libboost-iostreams-dev libboost-graph-dev \
    openjdk-21-jre-headless \
    python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /procurator
COPY src/dslc/requirements.txt src/dslc/requirements.txt
COPY artifact/docker/abseil-cpp-20240116.1.tar.gz artifact/docker/
COPY artifact/scripts/setup_gemcutter.sh artifact/scripts/
COPY src/p4b/source/ src/p4b/source/

RUN python3 -m venv .venv-wsl \
    && .venv-wsl/bin/pip install --no-cache-dir -r src/dslc/requirements.txt

# P4C_USE_PREINSTALLED_BDWGC=ON uses the system libgc instead of a
# FetchContent git clone, which keeps the image build reproducible.
# ENABLE_CONTROL_PLANE=OFF skips the p4runtime git clone and Protobuf;
# the verify backend does not need them.
# Abseil comes from the vendored, sha256-pinned tarball under
# artifact/docker/ instead of a network download.
ARG JOBS=
RUN mkdir -p /opt/deps/abseil-src \
    && tar -xf artifact/docker/abseil-cpp-20240116.1.tar.gz -C /opt/deps/abseil-src --strip-components=1 \
    && test -f /opt/deps/abseil-src/CMakeLists.txt
RUN mkdir -p src/p4b/source/build-host \
    && cd src/p4b/source/build-host \
    && cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF -DENABLE_CONTROL_PLANE=OFF \
       -DP4C_USE_PREINSTALLED_BDWGC=ON \
       -DFETCHCONTENT_SOURCE_DIR_ABSEIL=/opt/deps/abseil-src .. \
    && cmake --build . --target p4c-translator -j"${JOBS:-$(nproc)}"

# Pinned Ultimate/GemCutter release (version + sha256 fixed in the script).
RUN INSTALL_ROOT=/opt/ultimate artifact/scripts/setup_gemcutter.sh

# ---------- runtime stage ----------
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates python3 gcc \
    openjdk-21-jre-headless z3 \
    libgc1 libboost-iostreams1.83.0 zlib1g libbz2-1.0 liblzma5 libzstd1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /procurator
COPY src/bin src/bin
COPY src/dslc src/dslc
COPY src/p4b/python src/p4b/python
COPY src/p4b/source/p4include src/p4b/source/p4include
COPY src/p4b/source/backends/tofino/bf-p4c/p4include src/p4b/source/backends/tofino/bf-p4c/p4include
COPY --from=build /procurator/src/p4b/source/build-host/p4include src/p4b/source/build-host/p4include
COPY --from=build /procurator/src/p4b/source/build-host/backends/verify/p4c-translator src/p4b/source/build-host/backends/verify/p4c-translator
COPY --from=build /procurator/src/p4b/source/build-host/backends/verify/p4include src/p4b/source/build-host/backends/verify/p4include
COPY benchmarks benchmarks
COPY artifact artifact
COPY docs docs
COPY --from=build /procurator/.venv-wsl .venv-wsl
COPY --from=build /opt/ultimate /opt/ultimate

# The CLI is also executed directly as ./src/bin/procurator (shebang:
# /usr/bin/env python3), so install its Python deps for the system
# interpreter too.
RUN /procurator/.venv-wsl/bin/pip install --no-cache-dir \
    --target=/usr/local/lib/python3.12/dist-packages \
    -r src/dslc/requirements.txt

ENV ULTIMATE=/opt/ultimate/UGemCutter-linux/Ultimate \
    PYTHONPATH=/procurator/src:/procurator/src/p4b/python

# Zip downloads and Windows checkouts lose exec bits; restore them here.
RUN chmod +x /procurator/artifact/docker/entrypoint.sh \
    /procurator/artifact/scripts/*.sh /procurator/artifact/docker/*.sh

ENTRYPOINT ["/procurator/artifact/docker/entrypoint.sh"]
CMD ["help"]
