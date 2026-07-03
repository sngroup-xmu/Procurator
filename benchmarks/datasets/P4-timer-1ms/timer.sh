#!/bin/bash

cd ../../bf-sde-9.2.0

. set_sde.bash

cd

cd JJH/P4-timer-1ms

./build.sh timer.p4

python3 conf.py

./run.sh timer

echo "555S"S