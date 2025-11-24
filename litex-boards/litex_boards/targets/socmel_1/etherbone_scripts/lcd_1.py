#!/usr/bin/env python3

import time


from litex import RemoteClient

wb = RemoteClient(csr_csv="/home/alberto/socmel_1/litex-boards/litex_boards/targets/test/build/sipeed_tang_primer_20k/csr.csv" )
wb.open()


for i in range(240*45):
    # Write to a memory-mapped register
        wb.write(0xf0000000, 0x1fd)
        wb.write(0xf0000000, 0x180)

for i in range(240*45):
    # Write to a memory-mapped register
        wb.write(0xf0000000, 0x100)
        wb.write(0xf0000000, 0x11f)


for i in range(240*46):
    # Write to a memory-mapped register
        wb.write(0xf0000000, 0x1f1)
        wb.write(0xf0000000, 0x100)

wb.close()

