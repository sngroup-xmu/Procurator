
spin -a main.pml
gcc -DVECTORSZ=4096 -DNFAIR=3  -o pan pan.c
./pan -a -f -m100000 > results/result_eventually_one_chan

# if *.trail
# spin -t -g -l -s -r main.pml > results/debug_invariance_one_chan
#rm -rf pan*
#rm -rf _spin_nvr.tmp
#rm -rf *.trail