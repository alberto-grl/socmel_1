#!/usr/bin/env python3

import time


from litex import RemoteClient

wb = RemoteClient(csr_csv="/home/alberto/socmel_1/litex-boards/litex_boards/targets/test/build/sipeed_tang_primer_20k/csr.csv" )
wb.open()

# Dump all CSR registers of the SoC
#for name, reg in wb.regs.__dict__.items():
#    print("0x{:08x} : 0x{:08x} {}".format(reg.addr, reg.read(), name))

val = wb.regs.sdr_periph_csr_r.read()
print(f"csr_r = {val:#x}")
print(hex(wb.read(0xF0000010)))
#print(f"Writing to address: {hex(wb.bases.leds)}")
#wb.regs.leds_out.write(0x73)
#print("Readback:", hex(wb.regs.leds_out.read()))
print("Writing")
print(hex(wb.read(0xF0000000)))
#wb.write(0xF0000000, 0xD)
print(hex(wb.read(0xF0000000)))

print("Reading")
# need to read all of the 128 bits, or transaction will not complete.
# regs.myperiph_csr_r.read() automatically handles multi-word reads using the CSR size info (size=4) 
base = 0xF0000010
for i in range(4):
    val = wb.read(base + i*4)
    print(f"Word {i}: {val:#010x}")



#wb.regs.leds_out.write(0x03)
#val = wb.regs.leds_out.read()
#print(f"LEDs = {val:#x}")

# Read from a memory-mapped register
value = wb.read(0xF000001c)
print("Buttons = ",value)



# For some reason registers need a dummy write at start
wb.write(0xF0000800, 0x0)
wb.write(0xF0000804, 0x1)
wb.write(0xF0000808, 0x2)
wb.write(0xF000080c, 0x3)

wb.write(0xF0000800, 0x1bf258bf)
wb.write(0xF0000804, 0x258bf258)
wb.write(0xF0000808, 0xa5a5a5a5)
wb.write(0xF000080c, 0x5a5a5a5a)


wb.write(0xF0000800, 0x1bf258bf)
wb.write(0xF0000804, 0x258bf258)
wb.write(0xF0000808, 0xa5a5a5a5)
wb.write(0xF000080c, 0x5a5a5a5a)

# for j in range(10):

# # Write to a memory-mapped register
#     wb.write(0xF0000800, 0x5a6b7c80+j)
#     wb.write(0xF0000804, 0x5a6b7c84+j)
#     wb.write(0xF0000808, 0x5a6b7c88+j)
#     wb.write(0xF000080c, 0x5a6b7c8c+j)

#     print("After Write")


#     base = 0xF0000810
#     for i in range(4):
#         val = wb.read(base + (i)*4)
#         print(f"Word csr2 {i}: {val:#010x}")




wb.close()

