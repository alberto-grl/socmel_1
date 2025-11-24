#!/bin/bash
cd /home/alberto/socmel_1/litex/litex/soc/software/my_c_test
source /home/alberto/socmel_1/bin/activate
 litex_term --speed=115200 /dev/ttyUSB1 --kernel=demo/demo.bin 
