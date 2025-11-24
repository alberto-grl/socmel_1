

from migen import *
from litex.soc.interconnect.csr import *


# ENABLE OR DISABLE COMMENTED PARAMETER FOR LEDS IN INSTANTIATE
LED_CONTROL_LCD_PERIPH = 0

class MyPeriph(Module, AutoCSR):
    def __init__(self, platform):
        btn_pads = platform.request_all("btn_n")

        if LED_CONTROL_LCD_PERIPH:
            led_pads = platform.request_all("led")
            # ENABLE OR DISABLE COMMENTED PARAMETER FOR LEDS IN INSTANTIATE

        lcd_pads = platform.request("spilcd")

        # 4x CSR storage registers (128-bit total)
        self._csr0 = CSRStorage(32)
        self._csr1 = CSRStorage(32)
        self._csr2 = CSRStorage(32)
        self._csr3 = CSRStorage(32)

        # CSR read-back (combine them into 128 bits)
        self._csr_r = CSRStatus(128)

        # Instantiate Verilog
        self.specials += Instance("myperiph",
            i_clk       = ClockSignal(),
            i_rst = ResetSignal(),

            # CSR Interface
            i_csr_we    = self._csr0.re,  # Simplified for now
            i_csr_wdata = Cat(self._csr0.storage, self._csr1.storage, self._csr2.storage, self._csr3.storage),
            o_csr_rdata = self._csr_r.status,
            i_csr_addr  = 0,  # Static, or add decoding logic later

            # GPIO
 
            i_btn_n     = btn_pads,

# ENABLE OR DISABLE PARAMETER FOR USE OF LEDS 
#            o_leds      = led_pads,
            o_lcd_bl    = lcd_pads.lcd_bl,
            o_lcd_data  = lcd_pads.lcd_data,
            o_lcd_rs    = lcd_pads.lcd_rs,
            o_lcd_cs    = lcd_pads.lcd_cs,
            o_lcd_clk   = lcd_pads.lcd_clk,
            o_lcd_resetn = lcd_pads.lcd_resetn,
        )
