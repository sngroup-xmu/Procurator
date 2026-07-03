FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates cmake g++ git openjdk-21-jdk python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /procurator
