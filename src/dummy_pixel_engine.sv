module dummy_pixel_engine
#(
    parameter H_CNT_WID,
    parameter V_CNT_WID
)
`ifdef USE_INTERFACES
(
    pixel_bus.producer pixIf
`else
(
    input logic pixIf_NEXT_FRAME,
    input logic pixIf_H_BLANKING,
    input logic [H_CNT_WID-1:0] pixIf_H_CNT,
    input logic [V_CNT_WID-1:0] pixIf_next_V_CNT,
    output logic [3:0] pixIf_r,
    output logic [3:0] pixIf_g,
    output logic [3:0] pixIf_b
`endif
);

`ifdef USE_INTERFACES
    // Dummy wires
    logic pixIf_NEXT_FRAME;
    logic [H_CNT_WID-1:0] pixIf_H_CNT;
    logic [V_CNT_WID-1:0] pixIf_next_V_CNT;
    logic [3:0] pixIf_r, pixIf_g, pixIf_b;

    assign {pixIf_NEXT_FRAME} = {pixIf.NEXT_FRAME};
    assign {pixIf_H_CNT, pixIf_next_V_CNT} = {pixIf.H_CNT, pixIf.next_V_CNT};
    assign {pixIf.r, pixIf.g, pixIf.b} = {pixIf_r, pixIf_g, pixIf_b};
`endif
    //assign {pixIf_r, pixIf_g, pixIf_b} = {pixIf_V_CNT, pixIf_H_CNT}[11:0];
    //assign {pixIf_r, pixIf_g, pixIf_b} = {3{pixIf_H_CNT[3:0]}};
    assign {pixIf_r, pixIf_g, pixIf_b} = {pixIf_next_V_CNT, pixIf_H_CNT};

endmodule
