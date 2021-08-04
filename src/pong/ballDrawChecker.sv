module ballDrawChecker 
#(
    parameter PIPELINE_STAGES,
    parameter H_CNT_WID,
    parameter BALL_WIDTH_LOG,
    parameter BALL_PIXSIZE
)(
    input logic CLK,
    input logic [H_CNT_WID-1:0] drawX,
    input logic [BALL_WIDTH_LOG-1:0] currentX,
    input logic isValidY,
    output logic isBallPos
);

    logic isValidX;

    assign isValidX = drawX >= currentX && drawX < currentX + BALL_PIXSIZE[H_CNT_WID-1:0];
    assign isBallPos = isValidX && isValidY;

endmodule
