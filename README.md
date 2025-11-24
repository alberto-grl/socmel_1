# socmel_1

Build SOC:

cd ~/socmel_1/litex-boards/litex_boards/targets/socmel_1
source /home/alberto/litex_venv/bin/activate
./sipeed_tang_primer_20k_soc_socmel_1.py --sys-clk-freq=48e6 --soc-csv=soc.csf --with-etherbone --cpu-type=vexriscv --cpu-variant=lite --l2-size=512 --with-spi-sdcard --eth-ip 192.168.11.50 --build --csr-csv build/sipeed_tang_primer_20k/csr.csv --doc

Make RiscV executable:

cd ~/socmel_1/litex/litex/soc/software/socmel_1
source /home/alberto/litex_venv/bin/activate
~/socmel_1/bin/litex_make_sdr_v1 --build-path=/home/alberto/socmel_1/litex-boards/litex_boards/targets/socmel_1/build/sipeed_tang_primer_20k_socmel_1	
