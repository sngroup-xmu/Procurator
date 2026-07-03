
spin -a main.pml
gcc -DVECTORSZ=4096 -o pan pan.c
./pan -m2000000 > verify_2000000