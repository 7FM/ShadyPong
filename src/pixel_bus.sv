`ifdef USE_INTERFACES
interface pixel_bus
#(
    parameter H_CNT_WID,
    parameter V_CNT_WID
)();
    logic NEXT_FRAME;
    logic H_BLANKING;
    logic [H_CNT_WID-1:0] H_CNT;
    logic [V_CNT_WID-1:0] next_V_CNT;
    logic [3:0] r;
    logic [3:0] g;
    logic [3:0] b;

    modport producer (
        input NEXT_FRAME, H_BLANKING, H_CNT, next_V_CNT,
        output r, g, b
    );

    modport consumer (
        input r, g, b,
        output H_CNT, next_V_CNT, NEXT_FRAME, H_BLANKING
    );
endinterface
`endif