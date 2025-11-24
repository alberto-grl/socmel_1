#!/usr/bin/env python3

import time


from litex import RemoteClient

wb = RemoteClient(csr_csv="/home/alberto/socmel_1/litex-boards/litex_boards/targets/test/build/sipeed_tang_primer_20k/csr.csv" )
wb.open()

# Dump all CSR registers of the SoC
#for name, reg in wb.regs.__dict__.items():
#    print("0x{:08x} : 0x{:08x} {}".format(reg.addr, reg.read(), name))

# For some reason registers need a dummy write at start
wb.write(0xF0000800, 0x0)
wb.write(0xF0000804, 0x1)
wb.write(0xF0000808, 0x2)
wb.write(0xF000080c, 0x3)

wb.write(0xF0000010, 0xa5a5a5a5)
wb.write(0xF0000014, 0xa5a5a5a5)
wb.write(0xF0000018, 0xa5a5a5a5)
wb.write(0xF000001c, 0x5a5a5a5a)

Frequency = 7072000
NCOstep = ((pow(2,64) * Frequency // 48000000))
NCOstepHi = NCOstep >> 32
NCOstepLo = NCOstep & 0x00000000ffffffff



print ("NCOstep ", hex(NCOstep))
print ("NCOstepHi ", hex(NCOstepHi))
print ("NCOstepLo ", hex(NCOstepLo))
wb.write(0xF0000000, NCOstepLo)
wb.write(0xF0000004, NCOstepHi)
wb.write(0xF0000008, 0xa5a5a5a5)
wb.write(0xF000000c, 0x5a5a5a5a)


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

