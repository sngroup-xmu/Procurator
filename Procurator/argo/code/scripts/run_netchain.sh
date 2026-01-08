spin -a main_model.pml
gcc -DSC -DVECTORSZ=81920 -o pan pan.c
./pan -a -m100000 > result