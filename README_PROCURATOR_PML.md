# P4-verification

Verification system for P4 Programs.

## Install dependencies


1. Install p4c [dependencies](https://github.com/p4lang/p4c/tree/main?tab=readme-ov-file#ubuntu-dependencies).

Most dependencies can be installed using `apt-get install`:
```
$ sudo apt-get install cmake g++ git automake libtool libgc-dev bison flex
libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev
libboost-graph-dev llvm pkg-config python3-pip
tcpdump

$ pip3 install scapy ply
```

Install Protobuf from source:
```
sudo wget https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protobuf-all-3.7.1.tar.gz
sudo tar -zxvf protobuf-all-3.7.1.tar.gz
cd protobuf-3.7.1
sudo ./autogen.sh
sudo ./configure
sudo make
sudo make check
sudo make install
sudo ldconfig    # refresh shared library cache
protoc --version # check
```

2. Install SPIN for model checking.

```
git clone git@github.com:nimble-code/Spin.git
cd Spin/
cd Src*
make
sudo cp spin /usr/bin/spin
spin -V # check
```


## Build the compiler.

```
cd code/Translator/
mkdir build
cd build
cmake ..
make -j4
```

## Run
