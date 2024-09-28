/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <xparameters.h>
#include <xil_io.h>
#include <xil_printf.h>
#include <xtime_l.h>
#include <stdint.h>

#define BASE_ADDR 0x40000000 // Base address for MM2C interface
#define C_ADDR_CTRL 0x00     // Control register address
#define C_ADDR_OP_A 0x04     // Operand A address
#define C_ADDR_OP_B 0x08     // Operand B address
#define C_ADDR_FPU_RESULT 0x0C // FPU result address
#define XTIME_CLK_FREQ_HZ 100000000 // Example for a 100 MHz clock

// Function prototypes
void sendToPL(float a, float b);
float fpuMultiplication(float a, float b);

XTime start, end;
XTime start2, end2;

int main() {
    float opA, opB; // Operands for user input
    double plTime, psTime;
    while(1){

    // Take user input for operands
    printf("Enter Operand A (float): ");
    fflush(stdout); // Flush the output buffer to ensure the prompt is displayed
    scanf("%f", &opA);

    printf("\nEnter Operand B (float): ");
    fflush(stdout); // Flush the output buffer to ensure the prompt is displayed
    scanf("%f", &opB);

    // Print operands
    printf("\nUsing user-defined operands:\n");
    printf("Operand A: %0.2f\n", opA);
    printf("Operand B: %0.2f\n", opB);

    // Measure time and send to PL (FPGA)
    XTime_GetTime(&start2);
    sendToPL(opA, opB);
    XTime_GetTime(&end2);
    plTime = (double)(end2 - start2) * 1000000.0 / XTIME_CLK_FREQ_HZ; // Convert to microseconds

    // Perform FPU multiplication on PS (Processor)
    XTime_GetTime(&start);
    float psResult = fpuMultiplication(opA, opB);
    XTime_GetTime(&end);
    psTime = (double)(end - start) * 1000000.0 / XTIME_CLK_FREQ_HZ; // Convert to microseconds

    // Get the result from PL (FPGA)
    float plResult = *(float*)(BASE_ADDR + C_ADDR_FPU_RESULT);

    // Print results
    printf("\nFPU Result from PL: %f\n", plResult);
    printf("Time taken for PL FPU multiplication: %0.2f microseconds\n", plTime);
    printf("FPU Result from PS: %f\n", psResult);
    printf("Time taken for PS FPU multiplication: %0.2f microseconds\n", psTime);
    printf("**********************************************************\n");
    }

    return 0;
}

void sendToPL(float a, float b) {
	//printf("The value received from user %f *********\n",a);
    XTime_GetTime(&start2);
    // Send data to PL via MM2C interface
    Xil_Out32(BASE_ADDR + C_ADDR_OP_A, *((uint32_t*)&a)); // Correct casting to uint32_t for operand A
    Xil_Out32(BASE_ADDR + C_ADDR_OP_B, *((uint32_t*)&b)); // Correct casting to uint32_t for operand B
//    Xil_Out32(BASE_ADDR + C_ADDR_CTRL, 0x01); // Start the FPU operation
    XTime_GetTime(&end2);
}

float fpuMultiplication(float a, float b) {
    // Perform multiplication in the PS
    return a * b;
}
