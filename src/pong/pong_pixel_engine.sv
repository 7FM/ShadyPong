module pong_pixel_engine
#(
    parameter WIDTH, parameter HEIGHT,
    parameter H_CNT_WID, parameter V_CNT_WID,
    parameter PIPELINE_STAGES,
    parameter BUTTON_LOW_ACTIVE,
    parameter BALL_PIXSIZE,
    parameter PLAYER_LEN,
    parameter PLAYER_WID,
    parameter BALL_COL_R=4'b1111, parameter BALL_COL_G=4'd0, parameter BALL_COL_B=4'd0,
    parameter PLAYER_1_COL_R=4'd0, parameter PLAYER_1_COL_G=4'b1111, parameter PLAYER_1_COL_B=4'd0,
    parameter PLAYER_2_COL_R=4'd0, parameter PLAYER_2_COL_G=4'd0, parameter PLAYER_2_COL_B=4'b1111,
    parameter BG_COL_R=4'd0, parameter BG_COL_G=4'd0, parameter BG_COL_B=4'd0
)(
    input logic pixIf_CLK,
    input logic rst_n,     // reset_n - low to reset
    input logic [3:0] ballSpeed,
    input logic [3:0] playerSpeed,
    input logic pixIf_NEXT_FRAME,
    input logic pixIf_H_BLANKING,
    input logic [H_CNT_WID-1:0] pixIf_H_CNT,
    input logic [V_CNT_WID-1:0] pixIf_next_V_CNT,
    output logic [3:0] pixIf_r,
    output logic [3:0] pixIf_g,
    output logic [3:0] pixIf_b,
    input logic player1YUp, 
    input logic player1YDown,
    input logic player2YUp, 
    input logic player2YDown
);

    //localparam WIDTH_LOG = $clog2(WIDTH);
    //localparam HEIGHT_LOG = $clog2(HEIGHT);
    localparam PLAYER_HEIGHT_LOG = $clog2(HEIGHT-PLAYER_LEN);
    localparam BALL_HEIGHT_LOG = $clog2(HEIGHT-BALL_PIXSIZE);
    localparam BALL_WIDTH_LOG = $clog2(WIDTH-BALL_PIXSIZE);

    logic [PLAYER_HEIGHT_LOG-1:0] player1Pos, player2Pos;
    logic [BALL_WIDTH_LOG-1:0] ballXPos;
    logic [BALL_HEIGHT_LOG-1:0] ballYPos;

    pong_game_engine_one_hot #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .BUTTON_LOW_ACTIVE(BUTTON_LOW_ACTIVE),
        .BALL_PIXSIZE(BALL_PIXSIZE),
        .PLAYER_LEN(PLAYER_LEN),
        .PLAYER_WID(PLAYER_WID),
        .PLAYER_HEIGHT_LOG(PLAYER_HEIGHT_LOG),
        .BALL_HEIGHT_LOG(BALL_HEIGHT_LOG),
        .BALL_WIDTH_LOG(BALL_WIDTH_LOG)
    ) gameEngine (
        .pixIf_CLK(pixIf_CLK),
        .rst_n(rst_n),
        .ballSpeed(ballSpeed),
        .playerSpeed(playerSpeed),
        .pixIf_NEXT_FRAME(pixIf_NEXT_FRAME),
        .player1YUp(player1YUp), 
        .player1YDown(player1YDown),
        .player2YUp(player2YUp), 
        .player2YDown(player2YDown),
        .player1Pos(player1Pos),
        .player2Pos(player2Pos),
        .ballXPos(ballXPos),
        .ballYPos(ballYPos)
    );

    logic isPlayer1, isPlayer2, isBall;

    logic [PIPELINE_STAGES:0] isPlayer1_reg, isPlayer2_reg, isBall_reg;

    // Propergate pipelines
    generate
        if (PIPELINE_STAGES) begin
            always_ff @(posedge pixIf_CLK, negedge rst_n) begin
                // Initialize registers
                if (~rst_n) begin
                    isPlayer1_reg <= {PIPELINE_STAGES+1{1'b0}};
                    isPlayer2_reg <= {PIPELINE_STAGES+1{1'b0}};
                    isBall_reg <= {PIPELINE_STAGES+1{1'b0}};
                end else begin
                    isPlayer1_reg <= {isPlayer1_reg[PIPELINE_STAGES-1:0], isPlayer1};
                    isPlayer2_reg <= {isPlayer2_reg[PIPELINE_STAGES-1:0], isPlayer2};
                    isBall_reg <= {isBall_reg[PIPELINE_STAGES-1:0], isBall};
                end
            end
        end else begin
            // Well not really regs
            assign {isPlayer1_reg, isPlayer2_reg, isBall_reg} = {isPlayer1, isPlayer2, isBall};
        end
    endgenerate

    logic isBallY, isPlayer1Y, isPlayer2Y;

    YPosChecker #(
        .V_CNT_WID(V_CNT_WID),
        .PLAYER_HEIGHT_LOG(PLAYER_HEIGHT_LOG),
        .PLAYER_LEN(PLAYER_LEN),
        .BALL_HEIGHT_LOG(BALL_HEIGHT_LOG),
        .BALL_PIXSIZE(BALL_PIXSIZE)
    ) yPosChecker (
        .CLK(pixIf_CLK),
        .rst_n(rst_n),
        .H_BLANK(pixIf_H_BLANKING),
        .nextY(pixIf_next_V_CNT),
        .ballYPos(ballYPos),
        .player1Pos(player1Pos),
        .player2Pos(player2Pos),
        .isBallY(isBallY),
        .isPlayer1Y(isPlayer1Y),
        .isPlayer2Y(isPlayer2Y)
    );

    playerDrawChecker #(
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .H_CNT_WID(H_CNT_WID),
        .PLAYER_WID(PLAYER_WID),
        .X_OFF(0)
    ) checkPlayer1 (
        .drawX(pixIf_H_CNT),
        .isValidY(isPlayer1Y),
        .isPlayerPos(isPlayer1)
    );
    playerDrawChecker #(
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .H_CNT_WID(H_CNT_WID),
        .PLAYER_WID(PLAYER_WID),
        .X_OFF(WIDTH-PLAYER_WID)
    ) checkPlayer2 (
        .drawX(pixIf_H_CNT),
        .isValidY(isPlayer2Y),
        .isPlayerPos(isPlayer2)
    );
    ballDrawChecker #(
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .H_CNT_WID(H_CNT_WID),
        .BALL_WIDTH_LOG(BALL_WIDTH_LOG),
        .BALL_PIXSIZE(BALL_PIXSIZE)
    ) checkBall (
        .drawX(pixIf_H_CNT),
        .currentX(ballXPos),
        .isValidY(isBallY),
        .isBallPos(isBall)
    );

    // Draw logic
    always_comb begin
        unique casez ({isPlayer1_reg[PIPELINE_STAGES], isPlayer2_reg[PIPELINE_STAGES], isBall_reg[PIPELINE_STAGES]})
            3'b1??: {pixIf_r, pixIf_g, pixIf_b} = {PLAYER_1_COL_R[3:0], PLAYER_1_COL_G[3:0], PLAYER_1_COL_B[3:0]};
            3'b01?: {pixIf_r, pixIf_g, pixIf_b} = {PLAYER_2_COL_R[3:0], PLAYER_2_COL_G[3:0], PLAYER_2_COL_B[3:0]};
            3'b001: {pixIf_r, pixIf_g, pixIf_b} = {BALL_COL_R[3:0], BALL_COL_G[3:0], BALL_COL_B[3:0]};
            default: {pixIf_r, pixIf_g, pixIf_b} = {BG_COL_R[3:0], BG_COL_G[3:0], BG_COL_B[3:0]};
        endcase
    end

endmodule
