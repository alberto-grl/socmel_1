set_device -name GW2A-18C GW2A-LV18PG256C8/I7
add_file sipeed_tang_primer_20k_socmel_1.cst
add_file sipeed_tang_primer_20k_socmel_1.sdc
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/myperiph.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/sdr_periph.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/Hilbert.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/NCO.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/pt8211_drive.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/SinCos.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/dds_ii.v
add_file /home/alberto/self_socmel_1/litex-boards/litex_boards/targets/socmel_1/sdr_periph/verilog/cic_filter.v
add_file /home/alberto/litex_venv/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv_Lite.v
add_file /home/alberto/socmel_1/litex-boards/litex_boards/targets/socmel_1/build/sipeed_tang_primer_20k_socmel_1/gateware/sipeed_tang_primer_20k_socmel_1.v
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -rw_check_on_ram 1
run all