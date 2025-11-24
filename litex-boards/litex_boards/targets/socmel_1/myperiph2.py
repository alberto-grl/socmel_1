

from migen import *
from litex.soc.interconnect.csr import *

class MyPeriph2(Module, AutoCSR):
    def __init__(self, platform):
       # btn_pads = platform.request_all("btn_n")

        # 4x CSR storage registers (128-bit total)
        self._csr0 = CSRStorage(32)
        self._csr1 = CSRStorage(32)
        self._csr2 = CSRStorage(32)
        self._csr3 = CSRStorage(32)

        # CSR read-back (combine them into 128 bits)
        self._csr_r = CSRStatus(128)

        # Instantiate Verilog
        self.specials += Instance("myperiph2",
            i_clk       = ClockSignal(),

            # CSR Interface
            i_csr2_we    = self._csr0.re,  # Simplified for now
            i_csr2_wdata = Cat(self._csr0.storage, self._csr1.storage, self._csr2.storage, self._csr3.storage),
            o_csr2_rdata = self._csr_r.status,
            i_csr2_addr  = 0,  # Static, or add decoding logic later

            # GPIO
         #   i_btn_n     = btn_pads,
        )
