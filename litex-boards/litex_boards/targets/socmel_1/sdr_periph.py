

from migen import *
from litex.soc.interconnect.csr import *


# ENABLE OR DISABLE COMMENTED PARAMETER FOR LEDS IN INSTANTIATE
LED_CONTROL_SDR_PERIPH = 1

class SDRPeriph(Module, AutoCSR):
    def __init__(self, platform):
       # btn_pads = platform.request_all("btn_n")
        sdr_pads = platform.request("sdr")
        if LED_CONTROL_SDR_PERIPH:
            led_pads = platform.request_all("led")

        # 4x CSR storage registers (128-bit total)
        self._csr0 = CSRStorage(32)
        self._csr1 = CSRStorage(32)
        self._csr2 = CSRStorage(32)
        self._csr3 = CSRStorage(32)

        # CSR read-back (combine them into 128 bits)
        self._csr_r = CSRStatus(128)

        # Instantiate Verilog
        self.specials += Instance("sdr_periph",
            i_clk       = ClockSignal(),
            i_rst = ResetSignal(),

            # CSR Interface
            i_csr_sdr_we    = self._csr0.re,  # Simplified for now
            i_csr_sdr_wdata = Cat(self._csr0.storage, self._csr1.storage, self._csr2.storage, self._csr3.storage),
            o_csr_sdr_rdata = self._csr_r.status,
            i_csr_sdr_addr  = 0,  # Static, or add decoding logic later

            # GPIO
         
            o_TX = sdr_pads.TX,
            o_TX_NCO = sdr_pads.TX_NCO,
            i_RFIn_p = sdr_pads.RFIn_p,
            i_RFIn_n = sdr_pads.RFIn_n,
            o_RFOut = sdr_pads.RFOut,
            # o_MOSI_I = sdr_pads.MOSI_I,
            # i_MISO_I = sdr_pads.MISO_I,
            # o_SCK_I = sdr_pads.SCK_I,
            # o_SSEL_I = sdr_pads.SSEL_I,
            # o_MOSI_Q = sdr_pads.MOSI_Q,
            # i_MISO_Q = sdr_pads.MISO_Q,
            # o_SCK_Q = sdr_pads.SCK_Q,
            # o_SSEL_Q = sdr_pads.SSEL_Q,
            o_HP_BCK = sdr_pads.HP_BCK,
            o_HP_WS = sdr_pads.HP_WS,
            o_HP_DIN = sdr_pads.HP_DIN,
            o_PA_EN = sdr_pads.PA_EN,
# ENABLE OR DISABLE COMMENTED PARAMETER FOR LEDS IN INSTANTIATE
            o_leds = led_pads,
        )
