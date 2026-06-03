// Module: fir_filter.v
// Description: 4-Tap Low-Pass Direct-Form FIR Filter
module fir_filter (
    input clk,
    input reset,
    input signed [7:0] data_in,
    output reg signed [15:0] data_out
);

    // Hardcoded 8-bit quantized coefficients from MATLAB
    wire signed [7:0] h0 = 8'd14;
    wire signed [7:0] h1 = 8'd49;
    wire signed [7:0] h2 = 8'd49;
    wire signed [7:0] h3 = 8'd14;

    // Delay line registers for storing past input samples
    reg signed [7:0] x0, x1, x2, x3;

    // Pipeline Multiplication-Accumulation (MAC) internal lines
    wire signed [15:0] m0, m1, m2, m3;
    wire signed [15:0] sum;

    // Shift register logic (Delay Line)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x0 <= 8'd0;
            x1 <= 8'd0;
            x2 <= 8'd0;
            x3 <= 8'd0;
        end else begin
            x0 <= data_in;
            x1 <= x0;
            x2 <= x1;
            x3 <= x2;
        end
    end

    // Direct Form Multiply operations
    assign m0 = x0 * h0;
    assign m1 = x1 * h1;
    assign m2 = x2 * h2;
    assign m3 = x3 * h3;

    // Combinational Accumulator Addition
    assign sum = m0 + m1 + m2 + m3;

    // Registered output to remove glitches and settle timing
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 16'd0;
        end else begin
            data_out <= sum;
        end
    end

endmodule

// Module: tb_fir_filter.v
`timescale 1ns / 1ps

module tb_fir_filter;

    reg clk;
    reg reset;
    reg signed [7:0] data_in;
    wire signed [15:0] data_out;

    // Instantiate Unit Under Test (UUT)
    fir_filter uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation (50 MHz clock speed -> 20ns period)
    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_fir_filter);
        // Initialize Signals
        clk = 0;
        reset = 1;
        data_in = 8'd0;

        // Release Reset
        #20;
        reset = 0;

        // Apply an Impulse input (Value = 10 at t=20ns)
        #20; data_in = 8'd10; 
        #20; data_in = 8'd0;
        
        // Wait for impulse to flush out through the 4 taps
        #80;

        // Apply constant step input sequence (Value = 20)
        data_in = 8'd20;
        #20; data_in = 8'd20;
        #20; data_in = 8'd20;
        #20; data_in = 8'd20;
        #20; data_in = 8'd20;
        
        #100;
        $finish;
    end
      
endmodule
