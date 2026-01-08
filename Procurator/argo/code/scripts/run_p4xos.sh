spin -a main_model.pml
gcc -DSC -DVECTORSZ=1780000 -o pan pan.c
#gcc -DBITSTATE -DVECTORSZ=1780000 -o pan pan.c
./pan -a -m100000 > result