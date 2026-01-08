spin -a main_model.pml
gcc -DNOBOUNDCHECK -DNOFAIR -DSC -DVECTORSZ=13000 -o pan pan.c
./pan -a -m100000 > result_chan5_h1h3_times21