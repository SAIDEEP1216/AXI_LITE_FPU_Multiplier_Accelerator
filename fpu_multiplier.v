`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.09.2024 20:14:23
// Design Name: 
// Module Name: FPU_Multiplier
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module fpu_multiplier (
    input wire        clk,
    input wire        rst_n,
    input wire [31:0] a, // First operand
    input wire [31:0] b, // Second operand
    output reg [31:0] result // Result of multiplication
);

    wire sign_a, sign_b, sign_result;
    wire [7:0] exp_a, exp_b;
    wire [23:0] mant_a, mant_b;
    wire [47:0] mant_result;
    wire [8:0] exp_result;

    // Extract fields
    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];
    assign mant_a = {1'b1, a[22:0]}; // Implicit leading 1
    assign mant_b = {1'b1, b[22:0]}; // Implicit leading 1

    // Multiply mantissas
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
        end
    end

endmodule
