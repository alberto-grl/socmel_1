// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

//GIT: Submodule litex, branch LCDRiscV


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <irq.h>
#include <libbase/uart.h>
#include <libbase/console.h>
#include <generated/csr.h>
#include <generated/soc.h>

#include "lvgl.h"
#include "/home/alberto/lvgl/src/drivers/display/st7789/lv_st7789.h"

#define LCD_H_RES       135
#define LCD_V_RES       240

#define TIMER0_IRQ   1   // from interrupts.rst

#define S_F_OFFSET -330
#define SAMPLE_FREQUENCY (48000000 + S_F_OFFSET);  //SDR sampling frequency of RF ADC

#define BTN_0 (1)
#define BTN_1 (2)
#define BTN_2 (4)
#define BTN_3 (8)
#define BTN_4 (16)
#define BTN_5 (32)

#define LSB (0)
#define USB (1)

lv_display_t *lcd_disp;
lv_obj_t *label;
lv_obj_t *label2;
lv_obj_t * bar1;

volatile int lcd_bus_busy = 0;
int32_t bar1_value;
uint32_t NCOFrequency = 7074000;
uint64_t NCOIncrement;
uint32_t NCOIncrementHi;
uint32_t NCOIncrementLo;
uint8_t AudioVol = 0;
uint8_t DesiredSideband = 0;
uint8_t prev_DesiredSideband = 0;

//This array should be provided by libgcc.a, but for some reason it is not found
const uint8_t __clz_tab[256] =
{
  0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
};

void ui_init(lv_display_t *disp);
void LVGL_Task(void);

#define TICKS_PER_MS (CONFIG_CLOCK_FREQUENCY / 1000)


static void ms_tick_isr(void) {
    // Clear the interrupt
    timer0_ev_pending_write(1);

    // Your periodic code here
    lv_tick_inc(1);

    //printf("1 ms tick!\n");
}

void timer0_init(void) {
    // Set reload value for 1 ms
    timer0_reload_write(TICKS_PER_MS);
    // Enable timer (auto-reload mode)
    timer0_en_write(1);
    // Enable timer event
    timer0_ev_enable_write(1);

    // Register handler in the IRQ table
    irq_attach(TIMER0_IRQ, ms_tick_isr);

    // Enable this interrupt in the mask
    irq_setmask(irq_getmask() | (1 << TIMER0_IRQ));
    irq_setie(1); // global interrupt enable
}

uint64_t get_ticks(void) {
    // For 32-bit timer (common configuration)
    return timer0_value_read();
    
    // For 64-bit timer (if configured)
    // return timer0_value_hi_read() << 32 | timer0_value_lo_read();
}

void busy_wait_100ns() {

        asm volatile ("nop"); // No operation
        asm volatile ("nop"); // No operation
        asm volatile ("nop"); // No operation
    }




/* Platform-specific implementation of the LCD send command function. In general this should use polling transfer. */
    static void lcd_send_cmd(lv_display_t *disp, const uint8_t *cmd, size_t cmd_size, const uint8_t *param, size_t param_size)
    {
        uint8_t i;
        LV_UNUSED(disp);
  //      printf("LCD send_cmd size %d param_size %d\n", cmd_size, param_size);
        while (lcd_bus_busy) {};   /* wait until previous transfer is finished */
        /* send command */
        for (i=0; i<cmd_size; i++)
        {
            myperiph_csr0_write(cmd[i]);
  //          printf("LCD cmd %x\n", cmd[i]);
            busy_wait_100ns();
        }
        for (i=0; i<param_size; i++)
        {
            myperiph_csr0_write(param[i] + 0x100);
  //          printf("LCD param %x\n", param[i]);
            busy_wait_100ns();
        }
        lcd_bus_busy = 0;
    }

/* Platform-specific implementation of the LCD send color function. For better performance this should use DMA transfer.
 * In case of a DMA transfer a callback must be installed to notify LVGL about the end of the transfer.
 */
    static void lcd_send_color(lv_display_t *disp, const uint8_t *cmd, size_t cmd_size, uint8_t *param, size_t param_size)
    {
        uint16_t i;
        LV_UNUSED(disp);

 //       printf("LCD send_color size %d param_size %d\n", cmd_size, param_size);
        while (lcd_bus_busy) {};   /* wait until previous transfer is finished */

        /* send command */
        for (i=0; i<cmd_size; i++)
        {
            myperiph_csr0_write(cmd[i]);
 //           printf("LCD color cmd %x\n", cmd[i]);
            busy_wait_100ns();
        }
        //LSB and MSB are swapped, there should be an lvgl parameter that takes this into account
        //for now it is swapped here
        for (i=0; i<param_size; i=i+2)
        {
            myperiph_csr0_write(param[i+1] + 0x100);
//            printf("LCD param msb %x\n", param[i+1]);
            busy_wait_100ns();
            myperiph_csr0_write(param[i] + 0x100);
//           printf("LCD param lsb %x\n", param[i]);
            busy_wait_100ns();
        }

        
        lcd_bus_busy = 0;
        lv_display_flush_ready(lcd_disp);
    }


    void LVGL_Task(void)
    {
        /* Initialize LVGL */
        lv_init();

        /* Create the LVGL display object and the LCD display driver */
        lcd_disp = lv_st7789_create(LCD_H_RES, LCD_V_RES, LV_LCD_FLAG_NONE , lcd_send_cmd, lcd_send_color);

        lv_display_set_rotation(lcd_disp, LV_DISPLAY_ROTATION_270);

        /* Allocate draw buffers on the heap. In this example we use two partial buffers of 1/10th size of the screen */
        lv_color_t * buf1 = NULL;
        lv_color_t * buf2 = NULL;

        uint32_t buf_size = LCD_H_RES * LCD_V_RES / 10 * lv_color_format_get_size(lv_display_get_color_format(lcd_disp));

        buf1 = lv_malloc(buf_size);
        if(buf1 == NULL) {
            LV_LOG_ERROR("display draw buffer malloc failed");
            return;
        }

        buf2 = lv_malloc(buf_size);
        if(buf2 == NULL) {
            LV_LOG_ERROR("display buffer malloc failed");
            lv_free(buf1);
            return;
        }
        lv_display_set_buffers(lcd_disp, buf1, buf2, buf_size, LV_DISPLAY_RENDER_MODE_PARTIAL);
        lv_lcd_generic_mipi_set_gap(lcd_disp,40,53); //values from Sipeed demo initializing: 40, 53

    }


    void ui_init(lv_display_t *disp) {

            /* set screen background to black */
        lv_obj_t *scr = lv_screen_active();
        lv_obj_set_style_bg_color(scr, lv_color_hex(0x000000), 0);
        lv_obj_set_style_bg_opa(scr, LV_OPA_100, 0);


        LV_IMG_DECLARE(army_panel);
        lv_obj_t * img1 = lv_image_create(lv_scr_act());
        lv_img_set_src(img1, &army_panel);
        lv_obj_align(img1, LV_ALIGN_CENTER, 0, 0);
        lv_obj_set_size(img1, 240, 135);

            // create label 
        LV_FONT_DECLARE(lv_font_scoreboard_32 );
        label = lv_label_create(scr);
        lv_obj_set_align(label, LV_ALIGN_OUT_TOP_LEFT);
        lv_obj_set_height(label, LV_SIZE_CONTENT);
        lv_obj_set_width(label, LV_SIZE_CONTENT);
    lv_obj_set_pos(label, 38 , 28);    // Or in one function 
    //lv_obj_set_style_text_font(label, &lv_font_montserrat_32, 0);
    
    lv_obj_set_style_text_font(label, &lv_font_scoreboard_32 , 0);
    lv_obj_set_style_text_color(label, lv_color_hex(0xffbf00), 0);
    lv_label_set_recolor(label, true);                      //Enable re-coloring by commands in the text
    lv_label_set_text(label, "Hello World!");

    label2  = lv_label_create(lv_screen_active());
    lv_label_set_long_mode(label2, LV_LABEL_LONG_MODE_SCROLL_CIRCULAR);     //Circular scroll
    lv_obj_set_width(label2, 100);
    lv_label_set_text(label2, "START VALUE ");
    lv_obj_set_pos(label2, 42 , 78);   
    lv_obj_set_style_text_color(label2, lv_color_hex(0xffbf00), 0);
    lv_obj_set_style_text_font(label2, &lv_font_scoreboard_32, 0);
    lv_obj_set_style_anim_duration(label2, 4000, LV_PART_MAIN);

    bar1 = lv_bar_create(lv_screen_active());
    lv_obj_set_size(bar1, 38, 12);
    lv_obj_set_align(label, LV_ALIGN_OUT_TOP_LEFT);
    lv_obj_set_pos(bar1, 168 , 88); 
    lv_obj_set_style_bg_color(bar1, lv_color_hex(0xffbf00), LV_PART_INDICATOR);
    lv_obj_set_style_bg_color(bar1, lv_color_hex(0x181713), LV_PART_MAIN);
    lv_bar_set_value(bar1, bar1_value, LV_ANIM_OFF);



}


/*-----------------------------------------------------------------------*/
/* Uart                                                                  */
/*-----------------------------------------------------------------------*/

static char *readstr(void)
{
   char c[2];
   static char s[64];
   static int ptr = 0;

   if(readchar_nonblock()) {
      c[0] = getchar();
      c[1] = 0;
      switch(c[0]) {
      case 0x7f:
      case 0x08:
         if(ptr > 0) {
            ptr--;
            fputs("\x08 \x08", stdout);
        }
        break;
    case 0x07:
     break;
 case '\r':
 case '\n':
     s[ptr] = 0x00;
     fputs("\n", stdout);
     ptr = 0;
     return s;
 default:
     if(ptr >= (sizeof(s) - 1))
        break;
    fputs(c, stdout);
    s[ptr] = c[0];
    ptr++;
    break;
}
}

return NULL;
}

static char *get_token(char **str)
{
   char *c, *d;

   c = (char *)strchr(*str, ' ');
   if(c == NULL) {
      d = *str;
      *str = *str+strlen(*str);
      return d;
  }
  *c = 0;
  d = *str;
  *str = c+1;
  return d;
}

static void prompt(void)
{
   printf("\e[92;1mSoCmel_1 sdr_v1\e[0m> ");
}


uint8_t ButtonStatus(uint8_t n_button)
{ 
    return !(csr_read_simple(0xf000001c) & (1<<n_button));
}

uint32_t ButtonRaw()
{ 
    return (~csr_read_simple(0xf000001c) & 0x1f);
}

int main(void)
{
 char msg[20]; 
 uint8_t color;
 int i;
#ifdef CONFIG_CPU_HAS_INTERRUPT
 irq_setmask(0);
 irq_setie(1);
#endif

 timer0_init();

 uart_init();

 prompt();
 
 LVGL_Task();

    myperiph_csr0_write(0x021); //FPGA initializes ST7789 for reverse colors. This line sets it back to normal 
    busy_wait_100ns();
    myperiph_csr0_write(0x03a);
    busy_wait_100ns();
    myperiph_csr0_write(0x155);
    busy_wait_100ns();


    ui_init(lcd_disp);

    for(;;) {
        i+=1;
        if (i > 50) i = 0;

    // Display NCOFrequency with a dot before the last 3 digits, right justified, 9 chars wide, padded with spaces
        snprintf(msg, sizeof(msg), "%5ld.%03ld", NCOFrequency/1000, NCOFrequency%1000);
    //lv_obj_set_pos(label, 38 , 28);

        lv_label_set_text(label, msg);

    // Button 1: up, Button 2: down, Button 0: cycle increment step
        static uint32_t nco_steps[] = {10, 1000, 100000, 1000000};
    static int nco_step_idx = 2; // default to 1000
    static int prev_btn0 = 0;

    int btn_step = (ButtonRaw() == BTN_4);
    static int prev_btn_step;

    // On rising edge of Button 0, cycle step
    if (btn_step && !prev_btn_step) {
        nco_step_idx = (nco_step_idx + 1) % (sizeof(nco_steps)/sizeof(nco_steps[0]));
    }
    
    prev_btn_step = btn_step;

    printf("ButtonRaw %d\n", ButtonRaw());
    printf("param %d\n", (DesiredSideband + ((AudioVol & 0xf) << 1)));
    
    if ((ButtonRaw() == BTN_1)) NCOFrequency += nco_steps[nco_step_idx];
    if ((ButtonRaw() == BTN_2)) NCOFrequency -= nco_steps[nco_step_idx];
    if ((ButtonRaw() == BTN_0 + BTN_1)) DesiredSideband = LSB;
    if ((ButtonRaw() == BTN_0 + BTN_2)) DesiredSideband = USB;
    if ((ButtonRaw() == BTN_3 + BTN_1) && (AudioVol < 5)) AudioVol += 1;
    if ((ButtonRaw() == BTN_3 + BTN_2) && (AudioVol > 0)) AudioVol -=1;;

    static uint32_t prev_NCOFrequency = 0;
    if (NCOFrequency != prev_NCOFrequency) {
        NCOIncrement = (pow(2,64) * NCOFrequency) / SAMPLE_FREQUENCY;
        NCOIncrementHi = NCOIncrement >> 32;
        NCOIncrementLo = NCOIncrement & 0x00000000ffffffff;

        sdr_periph_csr0_write(NCOIncrementLo);
        sdr_periph_csr1_write(NCOIncrementHi);
//        sdr_periph_csr2_write(NCOIncrementLo);  //toglimi - test led

        prev_NCOFrequency = NCOFrequency;
    }
    if (DesiredSideband != prev_DesiredSideband) {
     sdr_periph_csr2_write(DesiredSideband + ((AudioVol & 0xf) << 1));
     prev_DesiredSideband = DesiredSideband;
 }

 lv_bar_set_value(bar1, bar1_value, LV_ANIM_OFF);

    // Show nco_steps in human-readable form
 const char* nco_step_strs[] = {"10", "1K", "0M1", "1M"};

 if (DesiredSideband)
    snprintf(msg, sizeof(msg), "LSB VOL %d STEP %s", (AudioVol & 0xf), nco_step_strs[nco_step_idx]);
else
    snprintf(msg, sizeof(msg), "USB VOL %d STEP %s", (AudioVol & 0xf), nco_step_strs[nco_step_idx]);

lv_label_set_text(label2, msg);


    lv_timer_handler(); //same as lv_task_handler for LVGL v8.x+
    //    busy_wait(200);
}

return 0;
}
