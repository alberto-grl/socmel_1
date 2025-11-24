#!/bin/bash
cd /home/alberto/socmel_1/litex-boards/litex_boards/targets/socmel_1
source /home/alberto/socmel_1/bin/activate
./sipeed_tang_primer_20k_soc_socmel_1.py --sys-clk-freq=48e6 --soc-csv=soc.csf --build --csr-csv build/sipeed_tang_primer_20k/csr.csv --doc
