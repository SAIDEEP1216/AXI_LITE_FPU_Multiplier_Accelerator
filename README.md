
# Floating Point Multiplier Accelerator Using AXI Lite Interface on PYNQ Z1 SoC

## Project Overview

This project implements an AXI Floating Point Unit (FPU) Multiplier Accelerator on the PYNQ Z1 FPGA. It allows users to input two floating-point numbers via a COM port, performs multiplication both in the Programmable Logic (PL) and the Processing System (PS), and prints the results along with the time taken for both operations.

Note: PS - Processing System here is MCU present on Soc (ARM Cortex A9).

PL - Programmable Logic (FPGA).

## Project Components

1. **AXI Memory-Mapped to Custom (MM2C) Interface Design**:  
   The AXI MM2C interface connects the Processing System (PS) of the ZYNQ SoC with the Custom Logic (PL), allowing data transfer between the two. It facilitates communication by reading and writing data to specific addresses in the PL.

2. **FPU Multiplier Design**:  
   The FPU multiplier is implemented in Verilog and performs floating-point multiplication using the IEEE 754 standard. It takes two 32-bit floating-point inputs, performs multiplication, and outputs the result.

## Hardware and Software Used

- **Hardware**: PYNQ Z1 FPGA
- **Software**: 
  - Vitis for PS-Application development
  - Vivado for FPGA design
 
## Design Workflow

1. **IP Block Creation**:
   - Designed block IPs for both the FPU multiplier and the AXI MM2C interface in Vivado.
   - Connected these IPs to the ZYNQ processing system.

2. **Synthesis and Implementation**:
   - Synthesized and implemented the design within Vivado.
   - Exported the completed design as an XSA file.

3. **Application Development**:
   - Created an application project in Vitis using the exported XSA file.
   - Utilized Vitis drivers to manage communication and data transfer between the PS and PL.



# Floating Point Unit (FPU) Multiplier

## Overview

The Floating Point Unit (FPU) Multiplier is designed to perform multiplication of two 32-bit floating-point numbers based on the IEEE 754 standard. This module takes two operands, extracts their components (sign, exponent, and mantissa), performs the multiplication, and outputs the result.

## Module Description

### Inputs and Outputs

- **Inputs**:
  - `clk`: Clock signal for synchronization.
  - `rst_n`: Active-low reset signal.
  - `a`: First operand (32-bit floating-point number).
  - `b`: Second operand (32-bit floating-point number).

- **Output**:
  - `result`: Result of the multiplication (32-bit floating-point number).

### Internal Wires

- `sign_a`, `sign_b`: Sign bits of operands `a` and `b`.
- `sign_result`: Sign bit of the result.
- `exp_a`, `exp_b`: Exponent fields of operands `a` and `b`.
- `mant_a`, `mant_b`: Mantissa fields of operands `a` and `b,` including an implicit leading 1.
- `mant_result`: Result of multiplying the mantissas.
- `exp_result`: Resulting exponent after adjusting for bias.

## Functionality

1. **Field Extraction**:
   - The sign, exponent, and mantissa fields are extracted from the input operands `a` and `b`.
   - The mantissa fields are normalized to include an implicit leading 1.

2. **Mantissa Multiplication**:
   - The mantissas of the two operands are multiplied together to form `mant_result`.

3. **Exponent Calculation**:
   - The exponents of the operands are added together, and the bias (127) is subtracted to calculate the `exp_result`.

4. **Sign Determination**:
   - The sign of the result is determined using the XOR operation on the sign bits of the input operands.

5. **Result Normalization**:
   - The result is normalized based on the value of `mant_result`. If the most significant bit (MSB) of `mant_result` is set, it indicates the need to adjust the exponent and shift the mantissa.

6. **Handling Special Cases**:
   - Overflow and underflow conditions are handled:
     - If `exp_result` exceeds 255, the output is set to infinity.
     - If `exp_result` is less than or equal to 0, the output is set to zero.

### Sequential Logic

The result is updated in a clocked always block that resets on `rst_n`. This ensures that the multiplier behaves as a synchronous circuit.

## Code Snippet

```verilog
    assign mant_result = mant_a * mant_b;

    // Add exponents and adjust for bias
    assign exp_result = (exp_a + exp_b ) - 8'd127;

    // Determine the sign of the result
    assign sign_result = sign_a ^ sign_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'b0;
        end else begin
            // Always block for sequential logic
            // Normalize the result (simplified)
            if (mant_result[47]) begin
                result <= {sign_result, exp_result + 1, mant_result[46:24]}; // Shift right by 1 bit and increment exponent
            end else begin
                result <= {sign_result, exp_result, mant_result[45:23]};
            end

            // Handle special cases (simplified)
            if (exp_result >= 8'd255) begin
                result <= {sign_result, 8'd255, 23'd0}; // Overflow: result is infinity
            end else if (exp_result <= 8'd0) begin
                result <= {sign_result, 8'd0, 23'd0}; // Underflow: result is zero
            end
```


# Memory-Mapped to Custom (MM2C) Interface

## Overview

The Memory-Mapped to Custom (MM2C) interface allows the AXI master to communicate with a custom logic module, such as a Floating Point Unit (FPU) multiplier. This interface is implemented using AXI4-Lite protocol, which enables efficient communication for control and data transfer.

## Module Description

The MM2C interface manages the read and write operations between the AXI master and the custom logic. It includes a register map for controlling the operation of the FPU and reading results.

## Features

- **Inputs**:
  - `aclk`: AXI clock signal.
  - `aresetn`: Active-low reset signal.
  - `fpu_result`: Result output from the FPU multiplier.

- **Outputs**:
  - `s_axi_awready`: Indicates that the interface is ready to accept a write address.
  - `s_axi_wready`: Indicates that the interface is ready to accept write data.
  - `s_axi_bresp`: Provides write response status.
  - `s_axi_bvalid`: Indicates that the write response is valid.
  - `s_axi_arready`: Indicates that the interface is ready to accept a read address.
  - `s_axi_rdata`: Data read from the interface.
  - `s_axi_rresp`: Provides read response status.
  - `s_axi_rvalid`: Indicates that the read data is valid.
  - `a`: Operand A to be sent to the FPU.
  - `b`: Operand B to be sent to the FPU.

## Register Map

| Address  | Name          | Description                       |
|----------|---------------|-----------------------------------|
| `0x00`   | Control Reg   | Control signals for the FPU      |
| `0x04`   | Operand A     | Input operand A for FPU          |
| `0x08`   | Operand B     | Input operand B for FPU          |
| `0x0C`   | FPU Result     | Result output from FPU           |

## AXI Read/Write State Machines

### Write State Machine

The write state machine handles the following states:
- **S_WRIDLE**: Idle state, waiting for an address.
- **S_WRDATA**: Waiting for write data.
- **S_WRRESP**: Sending response after write completion.

### Read State Machine

The read state machine handles the following states:
- **S_RDIDLE**: Idle state, waiting for a read address.
- **S_RDDATA**: Sending read data in response to a read request.

![Block_Diagram](https://github.com/user-attachments/assets/1a443970-1845-4c74-8b93-03c2ebf4b8a7)
***************************************************************************************************


# Vitis Application

## Overview

Using this application user can Input 2 floating-point values from the Serial terminal and result is calculated by both PS and PL and both results are displayed with time taken.

USART0 of PS is utilized for serial communication.

## Features

- **User Input**: Takes floating-point operands from the user.
- **FPGA Offload**: Sends operands to the PL for multiplication using an FPU.
- **Performance Measurement**: Measures and compares execution times for FPU multiplication on both PS and PL.

## Dependencies

- Xilinx hardware libraries (`xparameters.h`, `xil_io.h`, `xil_printf.h`, `xtime_l.h`).
- A working ZYNQ FPGA environment.

## Application Flow

1. **User Input**: The application prompts the user to enter two floating-point numbers.
2. **Send to PL**: The operands are sent to the PL via the MM2C interface.
3. **Time Measurement**: The application measures the time taken for both PL and PS multiplication.
4. **Results Display**: The results and execution times are printed to the console.

## Code Snippet

Below is a brief overview of the key functions in the application:

### Main Function

```c
int main() {
    float opA, opB; // Operands for user input
    double plTime, psTime;

    while(1) {
        // User input for operands
        ...
        // Send to PL
        sendToPL(opA, opB);
        ...
        // Get result from PL
        float plResult = *(float*)(BASE_ADDR + C_ADDR_FPU_RESULT);
        ...
    }
    return 0;
//For sending data to PS
void sendToPL(float a, float b) {
    // Send data to PL via MM2C interface
    Xil_Out32(BASE_ADDR + C_ADDR_OP_A, *((uint32_t*)&a)); // Send Operand A
    Xil_Out32(BASE_ADDR + C_ADDR_OP_B, *((uint32_t*)&b)); // Send Operand B
}
}

```
This application effectively utilizes the MM2C interface to offload floating-point multiplication tasks to the FPGA, showcasing the benefits of combining hardware acceleration with software processing.

***************************************
## Testing and Output

```plaintext
Enter Operand A (float): 
Enter Operand B (float): 
Using user-defined operands:
Operand A: 2.70
Operand B: 2.54

FPU Result from PL: 6.852920
Time taken for PL FPU multiplication: 2.79 microseconds
FPU Result from PS: 6.852920
Time taken for PS FPU multiplication: 0.33 microseconds
**********************************************************
Enter Operand A (float): 
Enter Operand B (float): 
Using user-defined operands:
Operand A: -2.68
Operand B: -4.57

FPU Result from PL: 12.235397
Time taken for PL FPU multiplication: 1.80 microseconds
FPU Result from PS: 12.235398
Time taken for PS FPU multiplication: 0.30 microseconds
**********************************************************
```
![1](https://github.com/user-attachments/assets/7a739fa4-90a9-4b12-8dda-b1b2f32427b6)
## Result

The application showcases the ability to offload FPU multiplication to the PL, but due to overhead associated with the MM2C interface and the FPGA's computation pipeline, the PS achieves slightly faster performance for this specific operation. However, for more complex and parallelized tasks, the PL would provide greater benefits in terms of scalability and efficiency.

