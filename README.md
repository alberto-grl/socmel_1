# socmel_1

Receiver can be tested without installing the full toolchain. Use the precompiled FPGA gateware:    
~/socmel_1/litex-boards/litex_boards/targets/socmel_1/build/sipeed_tang_primer_20k_socmel_1/gateware/sipeed_tang_primer_20k_socmel_1.fs     
Flash it with Gowin tools or openFPGAloader    

Binary executable for the RiscV MCU is at     
/home/alberto/socmel_1/litex/litex/soc/software/socmel_1/sdr_v1.bin      
Rename it boot.bin and write it at the root directory of an SD card.
More notes con be found at https://github.com/alberto-grl/Sipeed-Tang-Gowin-FPGA

For a complete environment install Litex, LVGL and the cross compiler tools.      
Expect some difficulties. Probably some directory references should be edited to suit your source tree location.    

Build SOC:

cd ~/socmel_1/litex-boards/litex_boards/targets/socmel_1       
source /home/alberto/litex_venv/bin/activate         
./sipeed_tang_primer_20k_soc_socmel_1.py --sys-clk-freq=48e6 --soc-csv=soc.csf --with-etherbone --cpu-type=vexriscv --cpu-variant=lite --l2-size=512 --with-spi-sdcard --eth-ip 192.168.11.50 --build --csr-csv build/sipeed_tang_primer_20k/csr.csv --doc        

Make RiscV executable:     

cd ~/socmel_1/litex/litex/soc/software/socmel_1      
source /home/alberto/litex_venv/bin/activate     
~/socmel_1/bin/litex_make_sdr_v1 --build-path=/home/alberto/socmel_1/litex-boards/litex_boards/targets/socmel_1/build/sipeed_tang_primer_20k_socmel_1	

Again, read https://github.com/alberto-grl/Sipeed-Tang-Gowin-FPGA for directions on how to proceed.


Receiver's performance is quite poor. Consider this a test bench for Litex and LVGL. Many stations can be heard, even from other continents, but there are more economical and better performing receivers.
LCD display is called "1.14 inches direct insertion". I bought mine from https://it.aliexpress.com/item/1005005586962823.html?spm=a2g0o.order_list.order_list_main.10.60993696ApPVmS&gatewayAdapt=glo2ita     
A lowpass or banpass filter is required, and a preamplifier. See schematics, but anything with 10-20 dB of gain should go.
Practical use shoud be on 40 meters and below, so a lowpass frequency of 7.5 MHz could be adequate. Some strong broadcast con be heard up to 16 MHz.     

Alberto I4NZX
