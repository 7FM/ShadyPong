module dummy_pixel_engine
#(
    parameter H_CNT_WID,
    parameter V_CNT_WID
)
(
    input logic pixIf_NEXT_FRAME,
    input logic pixIf_H_BLANKING,
    input logic [H_CNT_WID-1:0] pixIf_H_CNT,
    input logic [V_CNT_WID-1:0] pixIf_next_V_CNT,
    output logic [3:0] pixIf_r,
    output logic [3:0] pixIf_g,
    output logic [3:0] pixIf_b
);
    assign {pixIf_r, pixIf_g, pixIf_b} = {pixIf_next_V_CNT, pixIf_H_CNT};
endmodule
