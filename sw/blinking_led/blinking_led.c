/*
 * This file is part of the µOS++ distribution.
 *   (https://github.com/micro-os-plus)
 * Copyright (c) 2014 Liviu Ionescu.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom
 * the Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

// ----------------------------------------------------------------------------

//#include <stdio.h>
//#include <stdlib.h>
//
//#include "diag/Trace.h"
//#include "Timer.h"

// ----------------------------------------------------------------------------
//
// Print a greeting message on the trace device and enter a loop
// to count seconds.
//
// Trace support is enabled by adding the TRACE macro definition.
// By default the trace messages are forwarded to the DEBUG output,
// but can be rerouted to any device or completely suppressed, by
// changing the definitions required in system/src/diag/trace_impl.c
// (currently OS_USE_TRACE_ITM, OS_USE_TRACE_SEMIHOSTING_DEBUG/_STDOUT).
//
// ----------------------------------------------------------------------------

// Sample pragmas to cope with warnings. Please note the related line at
// the end of this function, used to pop the compiler diagnostics status.
//#pragma GCC diagnostic push
//#pragma GCC diagnostic ignored "-Wunused-parameter"
//#pragma GCC diagnostic ignored "-Wmissing-declarations"
//#pragma GCC diagnostic ignored "-Wreturn-type"
//
//int
//main (int argc, char* argv[])
//{
  // Normally at this stage most of the microcontroller subsystems, including
  // the clock, were initialised by the CMSIS SystemInit() function invoked
  // from the startup file, before calling main().
  // (see system/src/cortexm/_initialize_hardware.c)
  // If further initialisations are required, customise __initialize_hardware()
  // or add the additional initialisation here, for example:
  //
  // HAL_Init();

  // In this sample the SystemInit() function is just a placeholder,
  // if you do not add the real one, the clock will remain configured with
  // the reset value, usually a relatively low speed RC clock (8-12MHz).

  // Send a greeting to the trace device (skipped on Release).
//  trace_puts("Hello ARM World!");

  // At this stage the system clock should have already been configured
  // at high speed.
//  trace_printf("System clock: %u Hz\n", SystemCoreClock);
//
//  timer_start ();
//
//  int seconds = 0;

  // Infinite loop
//  while (1)
//    {
//      timer_sleep (TIMER_FREQUENCY_HZ);
//
//      ++seconds;
//
//      // Count seconds on the trace device.
//      trace_printf ("Second %d\n", seconds);
//    }
//  // Infinite loop, never return.
//}

//#pragma GCC diagnostic pop

// ----------------------------------------------------------------------------



// Obtained on "Application Note: Cortex-M0 Implementation in the Nexys2 FPGA
// Board – A Step by Step Guide."

// Define where the top of memory is.
#define TOP_OF_RAM 0x800U

// Define heap starts...
#define HEAP_BASE 0x47fU

//------------------------------------------------------------------------------
// Simple "Blinking Led via Memory Access detection" program.
//
// This program makes a memory access at regular intervals In the Nexys2 system
// there is a pattern detector attached to the HWRead bus, so when two specific
// patterns are detected, a Led toggles its state pattern 0xaaaa5555 turns on
// the led, pattern 0xf0f0f0f0 turns it off.
// -----------------------------------------------------------------------------

#define LedOn 0xaaaa5555
#define LedOff 0xf0f0f0f0

int main(void)
{
  unsigned int counter; // dummy
  unsigned int ii;      // loop iterator
  unsigned int trap;    // memory access pattern receiver
  unsigned int period;  // time interval for memory access
  /* period=20000000;    // period for FPGA implementation; roughly 3 seconds for a 10MHz osc in CM0_DS */
  period=200;           // period for simulations in ARM/Keil MDK and Xilinx ISIM tool

  while(1)
  {
    counter=0;
    for(ii=0; ii<period; ii++)
    {
      counter++;
    }
    trap=LedOn; // memory access pattern (turn on)
    /* trap=2863289685; // memory access pattern (turn on) */
    /* trap=0x42; // memory access pattern (turn on) */
    for(ii=0; ii<period; ii++)
    {
      counter++;
    }
    trap=LedOff;   // memory access pattern (turn off)
    /* trap=4042322160;   // memory access pattern (turn off) */
    /* trap=0x24;   // memory access pattern (turn off) */
    trap++;
    // dummy
  }
}

