`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.09.2024 20:32:07
// Design Name: 
// Module Name: mm2c_Interface
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



module mm2c_Interface(

        // ### Clock and reset signals #########################################
        input  wire        aclk,
        input  wire        aresetn,
        // ### AXI4-lite slave signals #########################################
        // *** Write address signals ***
        output wire        s_axi_awready,
        input  wire [31:0] s_axi_awaddr,
        input  wire        s_axi_awvalid,
        // *** Write data signals ***
        output wire        s_axi_wready,
        input  wire [31:0] s_axi_wdata,
        input  wire [3:0]  s_axi_wstrb,
        input  wire        s_axi_wvalid,
        // *** Write response signals ***
        input  wire        s_axi_bready,
        output wire [1:0]  s_axi_bresp,
        output wire        s_axi_bvalid,
        // *** Read address signals ***
        output wire        s_axi_arready,
        input  wire [31:0] s_axi_araddr,
        input  wire        s_axi_arvalid,
        // *** Read data signals ***    
        input  wire        s_axi_rready,
        output wire [31:0] s_axi_rdata,
        output wire [1:0]  s_axi_rresp,
        output wire        s_axi_rvalid,
        // ### User signals ####################################################
        // FPU output signals
        input wire [31:0]   fpu_result,
        // Outputs for operands
        output reg [31:0] a,
        output reg [31:0] b
    );

    // ### Register map ########################################################
    // 0x00: control register
    // 0x04: FPU operand A
    // 0x08: FPU operand B
    // 0x0C: FPU result
    localparam C_ADDR_BITS = 8;
    localparam C_ADDR_CTRL = 8'h00,
               C_ADDR_OP_A = 8'h04,
               C_ADDR_OP_B = 8'h08,
               C_ADDR_FPU_RESULT = 8'h0C;
    
    // *** AXI write FSM ***
    localparam S_WRIDLE = 2'd0,
               S_WRDATA = 2'd1,
               S_WRRESP = 2'd2;

    // *** AXI read FSM ***
    localparam S_RDIDLE = 2'd0,
               S_RDDATA = 2'd1;
    
    // *** AXI write ***
    reg [1:0] wstate_cs, wstate_ns;
    reg [C_ADDR_BITS-1:0] waddr;
    wire aw_hs, w_hs;
    
    // *** AXI read ***
    reg [1:0] rstate_cs, rstate_ns;
    wire [C_ADDR_BITS-1:0] raddr;
    reg [31:0] rdata;
    
    // *** Control registers ***
    reg [2:0] ctrl_reg;
    reg [31:0] op_a, op_b; // Operands for FPU
    
    // ### AXI write ###########################################################
    assign s_axi_awready = (wstate_cs == S_WRIDLE);
    assign s_axi_wready = (wstate_cs == S_WRDATA);
    assign s_axi_bresp = 2'b00;    // OKAY
    assign s_axi_bvalid = (wstate_cs == S_WRRESP);
    assign aw_hs = s_axi_awvalid & s_axi_awready;
    assign w_hs = s_axi_wvalid & s_axi_wready;

    // Write state register
    always @(posedge aclk) begin
        if (!aresetn)
            wstate_cs <= S_WRIDLE;
        else
            wstate_cs <= wstate_ns;
    end
    
    // Write state next
    always @(*) begin
        case (wstate_cs)
            S_WRIDLE:
                if (s_axi_awvalid)
                    wstate_ns = S_WRDATA;
                else
                    wstate_ns = S_WRIDLE;
            S_WRDATA:
                if (s_axi_wvalid)
                    wstate_ns = S_WRRESP;
                else
                    wstate_ns = S_WRDATA;
            S_WRRESP:
                if (s_axi_bready)
                    wstate_ns = S_WRIDLE;
                else
                    wstate_ns = S_WRRESP;
            default:
                wstate_ns = S_WRIDLE;
        endcase
    end
    
    // Write address register
    always @(posedge aclk) begin
        if (aw_hs)
            waddr <= s_axi_awaddr[C_ADDR_BITS-1:0];
    end
    
    // ### AXI read ############################################################
    assign s_axi_arready = (rstate_cs == S_RDIDLE);
    assign s_axi_rdata = rdata;
    assign s_axi_rresp = 2'b00;    // OKAY
    assign s_axi_rvalid = (rstate_cs == S_RDDATA);
    wire ar_hs = s_axi_arvalid & s_axi_arready;
    assign raddr = s_axi_araddr[C_ADDR_BITS-1:0];
    
    // Read state register
    always @(posedge aclk) begin
        if (!aresetn)
            rstate_cs <= S_RDIDLE;
        else
            rstate_cs <= rstate_ns;
    end

    // Read state next
    always @(*) begin
        case (rstate_cs)
            S_RDIDLE:
                if (s_axi_arvalid)
                    rstate_ns = S_RDDATA;
                else
                    rstate_ns = S_RDIDLE;
            S_RDDATA:
                if (s_axi_rready)
                    rstate_ns = S_RDIDLE;
                else
                    rstate_ns = S_RDDATA;
            default:
                rstate_ns = S_RDIDLE;
        endcase
    end
    
    // Read data register
    always @(posedge aclk) begin
        if (!aresetn)
            rdata <= 0;
        else if (ar_hs) begin
            case (raddr)
                C_ADDR_CTRL: 
                    rdata <= {ctrl_reg[2:0]};
                C_ADDR_OP_A:
                    rdata <= op_a; // Read operand A
                C_ADDR_OP_B:
                    rdata <= op_b; // Read operand B
                C_ADDR_FPU_RESULT:
                    rdata <= fpu_result; // Read from FPU result
            endcase
        end
    end
    
    // ### Control registers ###################################################
    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_reg[2:0] <= 0;
            op_a <= 32'b0; // Reset operand A
            op_b <= 32'b0; // Reset operand B
            a <= 32'b0; // Reset output a
            b <= 32'b0; // Reset output b
        end else if (w_hs) begin
            case (waddr)
                C_ADDR_CTRL:
                    ctrl_reg[2:0] <= (s_axi_wdata[2:0] & {4'b1111}) | (ctrl_reg[2:0] & ~{4'b1111});
                C_ADDR_OP_A:
                    begin
                        op_a <= s_axi_wdata; // Write operand A
                        a <= s_axi_wdata; // Update output a
                    end
                C_ADDR_OP_B:
                    begin
                        op_b <= s_axi_wdata; // Write operand B
                        b <= s_axi_wdata; // Update output b
                    end
            endcase
        end
    end

endmodule

















//module mm2c_Interface(

//        // ### Clock and reset signals #########################################
//        input  wire        aclk,
//        input  wire        aresetn,
//        // ### AXI4-lite slave signals #########################################
//        // *** Write address signals ***
//        output wire        s_axi_awready,
//        input  wire [31:0] s_axi_awaddr,
//        input  wire        s_axi_awvalid,
//        // *** Write data signals ***
//        output wire        s_axi_wready,
//        input  wire [31:0] s_axi_wdata,
//        input  wire [3:0]  s_axi_wstrb,
//        input  wire        s_axi_wvalid,
//        // *** Write response signals ***
//        input  wire        s_axi_bready,
//        output wire [1:0]  s_axi_bresp,
//        output wire        s_axi_bvalid,
//        // *** Read address signals ***
//        output wire        s_axi_arready,
//        input  wire [31:0] s_axi_araddr,
//        input  wire        s_axi_arvalid,
//        // *** Read data signals ***    
//        input  wire        s_axi_rready,
//        output wire [31:0] s_axi_rdata,
//        output wire [1:0]  s_axi_rresp,
//        output wire        s_axi_rvalid,
//        // ### User signals ####################################################
//        output wire        dir,
//        output wire        din,
//        output wire        en,
//        input wire [3:0]   q,
//        // FPU output signals
//        input wire [31:0]   fpu_result
//    );

//    // ### Register map ########################################################
//    // 0x00: enable (active high), data input, and shift direction (0: left, 1: right)
//    //       bit 0 = EN (R/W)
//    //       bit 1 = DIN (R/W)
//    //       bit 2 = DIR (R/W)
//    // 0x04: shift register data
//    //       bit 3~0 = SREG[3:0] (R)
//    // 0x08: FPU result
//    //       bit 31~0 = FPU_RESULT (R)
//    localparam C_ADDR_BITS = 8;
//    // *** Address ***
//    localparam C_ADDR_CTRL = 8'h00,
//               C_ADDR_SREG = 8'h04,
//               C_ADDR_FPU_RESULT = 8'h08;
//    // *** AXI write FSM ***
//    localparam S_WRIDLE = 2'd0,
//               S_WRDATA = 2'd1,
//               S_WRRESP = 2'd2;
//    // *** AXI read FSM ***
//    localparam S_RDIDLE = 2'd0,
//               S_RDDATA = 2'd1;
    
//    // *** AXI write ***
//    reg [1:0] wstate_cs, wstate_ns;
//    reg [C_ADDR_BITS-1:0] waddr;
//    wire [31:0] wmask;
//    wire aw_hs, w_hs;
//    // *** AXI read ***
//    reg [1:0] rstate_cs, rstate_ns;
//    wire [C_ADDR_BITS-1:0] raddr;
//    reg [31:0] rdata;
//    wire ar_hs;
//    // *** Control registers ***
//    reg [2:0] ctrl_reg;
    
//    // ### AXI write ###########################################################
//    assign s_axi_awready = (wstate_cs == S_WRIDLE);
//    assign s_axi_wready = (wstate_cs == S_WRDATA);
//    assign s_axi_bresp = 2'b00;    // OKAY
//    assign s_axi_bvalid = (wstate_cs == S_WRRESP);
//    assign wmask = {{8{s_axi_wstrb[3]}}, {8{s_axi_wstrb[2]}}, {8{s_axi_wstrb[1]}}, {8{s_axi_wstrb[0]}}};
//    assign aw_hs = s_axi_awvalid & s_axi_awready;
//    assign w_hs = s_axi_wvalid & s_axi_wready;

//    // *** Write state register ***
//    always @(posedge aclk)
//    begin
//        if (!aresetn)
//            wstate_cs <= S_WRIDLE;
//        else
//            wstate_cs <= wstate_ns;
//    end
    
//    // *** Write state next ***
//    always @(*)
//    begin
//        case (wstate_cs)
//            S_WRIDLE:
//                if (s_axi_awvalid)
//                    wstate_ns = S_WRDATA;
//                else
//                    wstate_ns = S_WRIDLE;
//            S_WRDATA:
//                if (s_axi_wvalid)
//                    wstate_ns = S_WRRESP;
//                else
//                    wstate_ns = S_WRDATA;
//            S_WRRESP:
//                if (s_axi_bready)
//                    wstate_ns = S_WRIDLE;
//                else
//                    wstate_ns = S_WRRESP;
//            default:
//                wstate_ns = S_WRIDLE;
//        endcase
//    end
    
//    // *** Write address register ***
//    always @(posedge aclk)
//    begin
//        if (aw_hs)
//            waddr <= s_axi_awaddr[C_ADDR_BITS-1:0];
//    end
    
//    // ### AXI read ############################################################
//    assign s_axi_arready = (rstate_cs == S_RDIDLE);
//    assign s_axi_rdata = rdata;
//    assign s_axi_rresp = 2'b00;    // OKAY
//    assign s_axi_rvalid = (rstate_cs == S_RDDATA);
//    assign ar_hs = s_axi_arvalid & s_axi_arready;
//    assign raddr = s_axi_araddr[C_ADDR_BITS-1:0];
    
//    // *** Read state register ***
//    always @(posedge aclk)
//    begin
//        if (!aresetn)
//            rstate_cs <= S_RDIDLE;
//        else
//            rstate_cs <= rstate_ns;
//    end

//    // *** Read state next ***
//    always @(*) 
//    begin
//        case (rstate_cs)
//            S_RDIDLE:
//                if (s_axi_arvalid)
//                    rstate_ns = S_RDDATA;
//                else
//                    rstate_ns = S_RDIDLE;
//            S_RDDATA:
//                if (s_axi_rready)
//                    rstate_ns = S_RDIDLE;
//                else
//                    rstate_ns = S_RDDATA;
//            default:
//                rstate_ns = S_RDIDLE;
//        endcase
//    end
    
//    // *** Read data register ***
//    always @(posedge aclk)
//    begin
//        if (!aresetn)
//            rdata <= 0;
//        else if (ar_hs)
//            case (raddr)
//                C_ADDR_CTRL: 
//                    rdata <= {ctrl_reg[2:0]};
//                C_ADDR_SREG:
//                    rdata <= q[3:0];
//                C_ADDR_FPU_RESULT:
//                    rdata <= fpu_result; // Read from FPU result
//            endcase
//    end
    
//    // ### Control registers ###################################################
//    assign dir = ctrl_reg[2];
//    assign din = ctrl_reg[1];
//    assign en = ctrl_reg[0];
    
//    always @(posedge aclk)
//    begin
//        if (!aresetn)
//        begin
//            ctrl_reg[2:0] <= 0;
//        end
//        else if (w_hs && waddr == C_ADDR_CTRL)
//        begin
//            ctrl_reg[2:0] <= (s_axi_wdata[2:0] & wmask) | (ctrl_reg[2:0] & ~wmask);
//        end
//        else
//        begin
//            ctrl_reg[0] <= 0;
//        end
//    end

//endmodule

