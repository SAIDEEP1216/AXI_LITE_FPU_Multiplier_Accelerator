

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
    float opA, opB; // User Inputs
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
    XTime_GetTime(&start2);
    // Send data to PL via MM2C interface
    Xil_Out32(BASE_ADDR + C_ADDR_OP_A, *((uint32_t*)&a)); // Correct casting to uint32_t for operand A
    Xil_Out32(BASE_ADDR + C_ADDR_OP_B, *((uint32_t*)&b)); // Correct casting to uint32_t for operand B
	
    XTime_GetTime(&end2);
}

float fpuMultiplication(float a, float b) {
    // Perform multiplication in the PS
    return a * b;
}
