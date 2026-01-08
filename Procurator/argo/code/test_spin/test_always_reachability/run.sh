spin -a 1.pml
# gcc -DNFAIR=3 -o pan pan.c
# ./pan -a -f -m100000 > result_fair
gcc -DSC -o pan pan.c
./pan -a -m100000 > result