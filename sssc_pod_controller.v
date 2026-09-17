//======================================================================
// SSSC POD CONTROLLER
// Target: AMD ZedBoard / Zynq-7000
//
// Controller:
//                     sTw        1+sT1       1+sT3
// Gpod(s) = K * ------------- * --------- * ---------
//                   1+sTw       1+sT2       1+sT4
//
// Inputs:
//   dw1, dw2       : rotor-speed deviations, signed Q16.16
//   sample_valid   : high for one controller sample update
//   discrete POD coefficients, signed Q16.16
//
// Internal POD input:
//   delta_w = dw1 - dw2
//
// Output:
//   vq_ref         : SSSC Vq reference, signed Q16.16
//   vq_ref_valid   : asserted for one cycle when vq_ref is updated
//
// MATLAB performs:
//   ACO optimization -> continuous parameters -> Tustin discretization
//   -> Q16.16 conversion -> HDL Verifier/FIL -> this FPGA controller
//======================================================================

module sssc_pod_controller #(
    parameter integer FRAC_BITS = 16
)(
    input  wire clk,
    input  wire rst,

    input  wire sample_valid,

    input  wire signed [31:0] dw1,
    input  wire signed [31:0] dw2,

    input  wire signed [31:0] coeff_aw,
    input  wire signed [31:0] coeff_bw,

    input  wire signed [31:0] coeff_a1,
    input  wire signed [31:0] coeff_b10,
    input  wire signed [31:0] coeff_b11,

    input  wire signed [31:0] coeff_a2,
    input  wire signed [31:0] coeff_b20,
    input  wire signed [31:0] coeff_b21,

    input  wire signed [31:0] coeff_k,

    output reg  signed [31:0] vq_ref,
    output reg                vq_ref_valid
);

    // Previous discrete states
    reg signed [31:0] delta_w_prev;
    reg signed [31:0] yw_prev;
    reg signed [31:0] y1_prev;
    reg signed [31:0] y2_prev;

    // Q16.16 multiply: (Q16.16 * Q16.16) >> 16
    function automatic signed [63:0] qmul;
        input signed [31:0] a;
        input signed [31:0] b;
        reg signed [63:0] product;
        begin
            product = a * b;
            qmul = product >>> FRAC_BITS;
        end
    endfunction

    // Saturate signed 64-bit value to signed 32-bit range
    function automatic signed [31:0] sat32;
        input signed [63:0] value;
        begin
            if (value > 64'sd2147483647)
                sat32 = 32'sh7FFFFFFF;
            else if (value < -64'sd2147483648)
                sat32 = 32'sh80000000;
            else
                sat32 = value[31:0];
        end
    endfunction

    // ---------------------------------------------------------------
    // Relative rotor-speed deviation
    // delta_w[k] = dw1[k] - dw2[k]
    // ---------------------------------------------------------------
    wire signed [63:0] delta_w_ext;
    wire signed [31:0] delta_w;

    assign delta_w_ext =
          {{32{dw1[31]}}, dw1}
        - {{32{dw2[31]}}, dw2};

    assign delta_w = sat32(delta_w_ext);

    // ---------------------------------------------------------------
    // Input difference for washout
    // dx[k] = delta_w[k] - delta_w[k-1]
    // ---------------------------------------------------------------
    wire signed [63:0] dx_ext;
    wire signed [31:0] dx;

    assign dx_ext =
          {{32{delta_w[31]}}, delta_w}
        - {{32{delta_w_prev[31]}}, delta_w_prev};

    assign dx = sat32(dx_ext);

    // ---------------------------------------------------------------
    // Washout:
    // yw[k] = Aw*yw[k-1] + Bw*(delta_w[k]-delta_w[k-1])
    // ---------------------------------------------------------------
    wire signed [63:0] wash_term1;
    wire signed [63:0] wash_term2;
    wire signed [63:0] wash_sum;
    wire signed [31:0] yw_new;

    assign wash_term1 = qmul(coeff_aw, yw_prev);
    assign wash_term2 = qmul(coeff_bw, dx);
    assign wash_sum   = wash_term1 + wash_term2;
    assign yw_new     = sat32(wash_sum);

    // ---------------------------------------------------------------
    // Lead-lag 1:
    // y1[k] = A1*y1[k-1] + B10*yw[k] + B11*yw[k-1]
    // ---------------------------------------------------------------
    wire signed [63:0] ll1_term1;
    wire signed [63:0] ll1_term2;
    wire signed [63:0] ll1_term3;
    wire signed [63:0] ll1_sum;
    wire signed [31:0] y1_new;

    assign ll1_term1 = qmul(coeff_a1,  y1_prev);
    assign ll1_term2 = qmul(coeff_b10, yw_new);
    assign ll1_term3 = qmul(coeff_b11, yw_prev);
    assign ll1_sum   = ll1_term1 + ll1_term2 + ll1_term3;
    assign y1_new    = sat32(ll1_sum);

    // ---------------------------------------------------------------
    // Lead-lag 2:
    // y2[k] = A2*y2[k-1] + B20*y1[k] + B21*y1[k-1]
    // ---------------------------------------------------------------
    wire signed [63:0] ll2_term1;
    wire signed [63:0] ll2_term2;
    wire signed [63:0] ll2_term3;
    wire signed [63:0] ll2_sum;
    wire signed [31:0] y2_new;

    assign ll2_term1 = qmul(coeff_a2,  y2_prev);
    assign ll2_term2 = qmul(coeff_b20, y1_new);
    assign ll2_term3 = qmul(coeff_b21, y1_prev);
    assign ll2_sum   = ll2_term1 + ll2_term2 + ll2_term3;
    assign y2_new    = sat32(ll2_sum);

    // ---------------------------------------------------------------
    // POD gain:
    // vq_ref[k] = K*y2[k]
    // ---------------------------------------------------------------
    wire signed [63:0] vq_mult;
    wire signed [31:0] vq_new;

    assign vq_mult = qmul(coeff_k, y2_new);
    assign vq_new  = sat32(vq_mult);

    // ---------------------------------------------------------------
    // State update
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            delta_w_prev <= 32'sd0;
            yw_prev      <= 32'sd0;
            y1_prev      <= 32'sd0;
            y2_prev      <= 32'sd0;
            vq_ref       <= 32'sd0;
            vq_ref_valid <= 1'b0;
        end
        else begin
            vq_ref_valid <= 1'b0;

            if (sample_valid) begin
                delta_w_prev <= delta_w;
                yw_prev      <= yw_new;
                y1_prev      <= y1_new;
                y2_prev      <= y2_new;

                vq_ref       <= vq_new;
                vq_ref_valid <= 1'b1;
            end
        end
    end

endmodule
