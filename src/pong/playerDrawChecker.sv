module playerDrawChecker 
#(
    parameter PIPELINE_STAGES,
    parameter H_CNT_WID,
    parameter PLAYER_WID,
    parameter X_OFF
)(
    input logic CLK,
    input logic [H_CNT_WID-1:0] drawX,
    input logic isValidY,
    output logic isPlayerPos
);

    logic isValidX;

    generate
        if (X_OFF == 0)
            assign isValidX = drawX < PLAYER_WID[H_CNT_WID-1:0];
        else
            assign isValidX = drawX >= X_OFF[H_CNT_WID-1:0];
    endgenerate
    assign isPlayerPos = isValidX && isValidY;

endmodule
