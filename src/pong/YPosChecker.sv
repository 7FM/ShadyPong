module YPosChecker
#(
    parameter V_CNT_WID,
    parameter PLAYER_HEIGHT_LOG,
    parameter PLAYER_LEN,
    parameter BALL_HEIGHT_LOG,
    parameter BALL_PIXSIZE
)
(
    input logic CLK,
    input logic H_BLANK,
    input logic [V_CNT_WID-1:0] nextY,
    input logic [BALL_HEIGHT_LOG-1:0] ballYPos,
    input logic [PLAYER_HEIGHT_LOG-1:0] player1Pos,
    input logic [PLAYER_HEIGHT_LOG-1:0] player2Pos,
    output logic isBallY,
    output logic isPlayer1Y,
    output logic isPlayer2Y
);

    typedef enum {
        YPC_IDLE = 0,
        YPC_START,
        YPC_CALC_BALL_Y_VALID,
        YPC_CALC_PLAYER_1_VALID,
        YPC_CALC_PLAYER_2_VALID,
        YPC_WAIT_FOR_LOW_BLANK
    } YPC_FSMState;

    logic hBlankingBuf;
    logic isBallY_reg, isPlayer1Y_reg, isPlayer2Y_reg, cmp_1, cmp_2;
    logic [V_CNT_WID-1:0] drawY_reg, cmpOpReg_1, cmpOpReg_2, next_cmpOpReg_1, next_cmpOpReg_2;

    logic triggerNextState;
    logic [YPC_WAIT_FOR_LOW_BLANK:0] fsmState, next_fsmState;

    assign {isBallY, isPlayer1Y, isPlayer2Y} = {isBallY_reg, isPlayer1Y_reg, isPlayer2Y_reg};
    // Wrap around shift
    assign next_fsmState = {fsmState[YPC_WAIT_FOR_LOW_BLANK-1:0], fsmState[YPC_WAIT_FOR_LOW_BLANK]};
    // State transition condition
    assign triggerNextState = !(fsmState[YPC_IDLE] || fsmState[YPC_WAIT_FOR_LOW_BLANK]) || (fsmState[YPC_WAIT_FOR_LOW_BLANK] && !hBlankingBuf) || (fsmState[YPC_IDLE] && hBlankingBuf);

    assign cmp_1 = drawY_reg >= cmpOpReg_1;
    assign cmp_2 = drawY_reg < cmpOpReg_2;

    initial begin
        hBlankingBuf = 1'b0;
        {isBallY_reg, isPlayer1Y_reg, isPlayer2Y_reg} = 3'b000;
        fsmState = ({{YPC_WAIT_FOR_LOW_BLANK{1'b0}}, 1'b1} << YPC_IDLE);
    end

    always_comb begin
        next_cmpOpReg_1 = cmpOpReg_1;
        next_cmpOpReg_2 = cmpOpReg_2;
        unique case (1'b1)
            fsmState[YPC_START]: begin
                next_cmpOpReg_1 = ballYPos;
                next_cmpOpReg_2 = ballYPos + BALL_PIXSIZE[V_CNT_WID-1:0];
            end
            fsmState[YPC_CALC_BALL_Y_VALID]: begin
                next_cmpOpReg_1 = player1Pos;
                next_cmpOpReg_2 = player1Pos + PLAYER_LEN[V_CNT_WID-1:0];
            end
            fsmState[YPC_CALC_PLAYER_1_VALID]: begin
                next_cmpOpReg_1 = player2Pos;
                next_cmpOpReg_2 = player2Pos + PLAYER_LEN[V_CNT_WID-1:0];
            end
            default: begin
                // Empty default case
            end
        endcase
    end

    always_ff @(posedge CLK) begin
        hBlankingBuf <= H_BLANK;
        fsmState <= triggerNextState ? next_fsmState : fsmState;
        drawY_reg <= fsmState[YPC_START] ? nextY : drawY_reg;
        isBallY_reg <= fsmState[YPC_CALC_BALL_Y_VALID] ? cmp_1 && cmp_2 : isBallY_reg;
        isPlayer1Y_reg <= fsmState[YPC_CALC_PLAYER_1_VALID] ? cmp_1 && cmp_2 : isPlayer1Y_reg;
        isPlayer2Y_reg <= fsmState[YPC_CALC_PLAYER_2_VALID] ? cmp_1 && cmp_2 : isPlayer2Y_reg;

        cmpOpReg_1 <= next_cmpOpReg_1;
        cmpOpReg_2 <= next_cmpOpReg_2;
    end

endmodule
