module pong_game_engine
#(
    parameter WIDTH,
    parameter HEIGHT,
    parameter BALL_PIXSIZE,
    parameter PLAYER_LEN,
    parameter PLAYER_WID,
    parameter PLAYER_MOVE_SPEED,
    parameter BALL_MOVE_SPEED,
    parameter PLAYER_HEIGHT_LOG,
    parameter BALL_HEIGHT_LOG,
    parameter BALL_WIDTH_LOG
)
(
    input logic pixIf_CLK,
    input logic pixIf_NEXT_FRAME,
    input logic player1YUp,
    input logic player1YDown,
    input logic player2YUp,
    input logic player2YDown,
    output logic [PLAYER_HEIGHT_LOG-1:0] player1Pos,
    output logic [PLAYER_HEIGHT_LOG-1:0] player2Pos,
    output logic [BALL_WIDTH_LOG-1:0] ballXPos,
    output logic [BALL_HEIGHT_LOG-1:0] ballYPos
);

    localparam PLAYER_START_POS = (HEIGHT-PLAYER_LEN) / 2;
    localparam BALL_START_POS_X = (WIDTH-BALL_PIXSIZE) / 2;
    localparam BALL_START_POS_Y = (HEIGHT-BALL_PIXSIZE) / 2;

    // Give the player some time to react!
    localparam BALL_START_POS_X_PLAYER_1 = BALL_START_POS_X + BALL_START_POS_X / 2;
    localparam BALL_START_POS_X_PLAYER_2 = BALL_START_POS_X - BALL_START_POS_X / 2;
    localparam __WIDTH_MIN_BALL_PIXELSIZE_MIN_PLAYER_WID = WIDTH - BALL_PIXSIZE - PLAYER_WID;
    localparam __HEIGHT_MIN_BALL_PIXSIZE = HEIGHT - BALL_PIXSIZE;

    //TODO make a create FSM with many steps for low resource requirements and possibly high clocks
    typedef enum {
        IDLE = 0,
        COLLISION_CHECK_START,
        COLLISION_CHECK_1,
        COLLISION_CHECK_2,
        COLLISION_CHECK_3,
        COLLISION_CHECK_4,
        COLLISION_CHECK_5,
        COLLISION_CHECK_6,
        COLLISION_CHECK_7,
        COLLISION_CHECK_8,
        COLLISION_CHECK_END,
        //TODO add more states
        CALC_NEXT_POS_BALL_X,
        CALC_NEXT_POS_BALL_Y,
        CALC_NEXT_POS_PLAYER_1,
        CALC_NEXT_POS_PLAYER_2,
        NORMAL_END,
        SCORE_END
    } FSMStates;

    FSMStates fsmState, next_fsmState, fsmStateAdd1;

    // BALL_HEIGHT_LOG and BALL_WIDTH_LOG are always larger than PLAYER_HEIGHT_LOG as the ball is smaller and has therefore a larger movement range
    localparam MAX_POS_LOG = BALL_WIDTH_LOG > BALL_HEIGHT_LOG ? BALL_WIDTH_LOG : BALL_HEIGHT_LOG;

    // Temporary variables
    logic tmpPosCmp;
    logic tmpPosCmp_reg_1, tmpPosCmp_reg_2, tmpPosCmp_reg_3, tmpPosCmp_reg_4;
    logic tmpPosCmp_1, tmpPosCmp_2, tmpPosCmp_3, tmpPosCmp_4;
    // Prevent overflows by using MAX_POS_LOG instead of MAX_POS_LOG-1... else this might burn
    logic [MAX_POS_LOG:0] tmpPosVar_reg_1, tmpPosVar_reg_2, tmpPosVar_1, tmpPosVar_2, tmpPosAdd, tmpPosAddOp1, tmpPosAddOp2, tmpPosCmpOp1, tmpPosCmpOp2;

    // Game variables: Coordinate system starts at upperleft with (0,0)
    logic ballMovesPosX, ballMovesPosY, nextBallMovesPosX, nextBallMovesPosY;
    logic [PLAYER_HEIGHT_LOG-1:0] nextPlayer1Pos, nextPlayer2Pos;
    logic [BALL_WIDTH_LOG-1:0] nextBallXPos;
    logic [BALL_HEIGHT_LOG-1:0] nextBallYPos;

    // Next pos operator
    logic dir;
    logic [MAX_POS_LOG-1:0] speed, boundary, currentPos, boundedNextPos;

    //TODO FML it now performs even worse than legacy!
    nextBoundedPosPipelined_ #(
        .POS_LOG_SIZE(MAX_POS_LOG)
    ) nextPosCalculator (
        .CLK(pixIf_CLK),
        .dir(dir),
        .speed(speed),
        .boundary(boundary),
        .currentPos(currentPos),
        .boundedNextPos(boundedNextPos)
    );

    assign fsmStateAdd1 = fsmState + 1;

    // State transitions
    always_comb begin
        unique case (fsmState)
            IDLE: begin
                next_fsmState = fsmState;
            end
            NORMAL_END, SCORE_END: begin
                next_fsmState = IDLE;
            end
            COLLISION_CHECK_END: begin
                //next_fsmState = tmpPosCmp_reg_1 ? SCORE_END : fsmStateAdd1;
                // ballCollidesPlayer || ~ballCollidesSides aka ~gameOver
                next_fsmState = tmpPosVar_reg_2[0] || tmpPosCmp_reg_3 ? fsmStateAdd1 : SCORE_END;
            end
            /*
            CALC_NEXT_POS_BALL_X, CALC_NEXT_POS_BALL_Y,
            CALC_NEXT_POS_PLAYER_1, CALC_NEXT_POS_PLAYER_2: begin
                next_fsmState = nextPosCalcDone ? fsmStateAdd1 : fsmState;
            end
            */
            default: begin
                next_fsmState = fsmStateAdd1;
            end
        endcase
    end

    // Operations:
    assign tmpPosAdd = tmpPosAddOp1 + tmpPosAddOp2;
    assign tmpPosCmp = tmpPosCmpOp1 < tmpPosCmpOp2;

    // Fixed path for reduced latency -> no additional mutex
    assign tmpPosVar_1 = tmpPosAdd;
    assign tmpPosCmp_1 = tmpPosCmp;

    // Control signals
    always_comb begin
        // Default values:
        tmpPosVar_2 = tmpPosVar_reg_2;
        tmpPosCmp_2 = tmpPosCmp_reg_2;
        tmpPosCmp_3 = tmpPosCmp_reg_3;
        tmpPosCmp_4 = tmpPosCmp_reg_4;
        nextBallMovesPosX = ballMovesPosX;
        nextBallMovesPosY = ballMovesPosY;
        nextPlayer1Pos = player1Pos;
        nextPlayer2Pos = player2Pos;
        nextBallXPos = ballXPos;
        nextBallYPos = ballYPos;
        // Default tasks
        tmpPosAddOp1 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};
        tmpPosAddOp2 = BALL_PIXSIZE[MAX_POS_LOG:0];
        tmpPosCmpOp1 = PLAYER_WID[MAX_POS_LOG:0];
        tmpPosCmpOp2 = {{(MAX_POS_LOG + 1 - BALL_WIDTH_LOG){1'b0}}, ballXPos};
        // Default tasks for next boundes pos calculator
        dir = ballMovesPosX;
        speed = ballMovesPosX ? BALL_MOVE_SPEED : -BALL_MOVE_SPEED;
        boundary = ballMovesPosX ? WIDTH - BALL_PIXSIZE - PLAYER_WID : PLAYER_WID;
        currentPos = {{(MAX_POS_LOG - BALL_WIDTH_LOG){1'b0}}, ballXPos};

        unique case (fsmState)
            COLLISION_CHECK_START: begin
                /*
                assign ballCollidesPlayer = (ballCollidesLeftBorder && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos) ||
                                            (ballCollidesRightBorder && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos);

                assign ballCollidesBounceBorders = ballYPos == 0 || (ballYPos == (HEIGHT - BALL_PIXSIZE));
                assign ballCollidesLeftBorder = ballXPos == PLAYER_WID;
                assign ballCollidesRightBorder = ballXPos == (WIDTH - BALL_PIXSIZE - PLAYER_WID);

                assign ballCollidesSides = ballCollidesLeftBorder || ballCollidesRightBorder;
                */
                // Start collision checks
                // Player collision checks: first calculate ballYPos + BALL_PIXSIZE
                tmpPosAddOp1 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};
                tmpPosAddOp2 = BALL_PIXSIZE[MAX_POS_LOG:0];
                // Ball X Border checks: collides with lower bound? ~(ballXPos > PLAYER_WID)
                tmpPosCmpOp1 = PLAYER_WID[MAX_POS_LOG:0];
                tmpPosCmpOp2 = {{(MAX_POS_LOG + 1 - BALL_WIDTH_LOG){1'b0}}, ballXPos};
                
                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: ballYPos + BALL_PIXSIZE
                tmpPosVar_reg_2: X
                (readOnly) tmpPosCmp_reg_1: (ballXPos > PLAYER_WID)
                tmpPosCmp_reg_2: X
                tmpPosCmp_reg_3: X
                tmpPosCmp_reg_4: X
                */
            end
            COLLISION_CHECK_1: begin
                // Player collision checks: calculate player1Pos + PLAYER_LEN
                tmpPosAddOp1 = {{(MAX_POS_LOG + 1 - PLAYER_HEIGHT_LOG){1'b0}}, player1Pos};
                tmpPosAddOp2 = PLAYER_LEN[MAX_POS_LOG:0];
                // Player collision check: player1Pos < ballYPos + BALL_PIXSIZE
                tmpPosCmpOp1 = tmpPosAddOp1;
                tmpPosCmpOp2 = tmpPosVar_reg_1;
                
                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: player1Pos + PLAYER_LEN
                tmpPosVar_reg_2: ballYPos + BALL_PIXSIZE
                (readOnly) tmpPosCmp_reg_1: player1Pos < ballYPos + BALL_PIXSIZE
                tmpPosCmp_reg_2: (ballXPos > PLAYER_WID)
                tmpPosCmp_reg_3: X
                tmpPosCmp_reg_4: X
                */
                // Move pos register 1 to register 2
                //tmpPosVar_2 = tmpPosVar_reg_1;
                //tmpPosCmp_2 = tmpPosCmp;

                // Move cmp register 1 to register 2 
                tmpPosCmp_2 = tmpPosCmp_reg_1;
            end
            COLLISION_CHECK_2: begin
                // Player collision checks: calculate player2Pos + PLAYER_LEN
                tmpPosAddOp1 = {{(MAX_POS_LOG + 1 - PLAYER_HEIGHT_LOG){1'b0}}, player2Pos};
                tmpPosAddOp2 = PLAYER_LEN[MAX_POS_LOG:0];
                // Player collision check: player1Pos + PLAYER_LEN > ballYPos
                tmpPosCmpOp1 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};
                tmpPosCmpOp2 = tmpPosVar_reg_1;

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: player2Pos + PLAYER_LEN
                tmpPosVar_reg_2: ballYPos + BALL_PIXSIZE
                (readOnly) tmpPosCmp_reg_1: player1Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_2: player1Pos < ballYPos + BALL_PIXSIZE
                tmpPosCmp_reg_3: ~(ballXPos > PLAYER_WID) aka ballCollidesLeftBorder
                tmpPosCmp_reg_4: X
                */
                //tmpPosCmp_1 = ~tmpPosCmp_reg_1;
                //tmpPosCmp_2 = tmpPosCmp_1 && tmpPosCmp_reg_2;
                //tmpPosCmp_3 = tmpPosCmp;

                // Move cmp register 1 to register 2 
                tmpPosCmp_2 = tmpPosCmp_reg_1;
                tmpPosCmp_3 = ~tmpPosCmp_reg_2;
            end
            COLLISION_CHECK_3: begin
                // TODO what use the addition in this cycle for?

                // Player collision check: player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmpOp1 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};
                tmpPosCmpOp2 = tmpPosVar_reg_1;

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2: ballYPos + BALL_PIXSIZE
                (readOnly) tmpPosCmp_reg_1: ~(ballXPos > PLAYER_WID) aka ballCollidesLeftBorder
                tmpPosCmp_reg_2: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                tmpPosCmp_reg_3: player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_4: X

                (readOnly) tmpPosCmp_reg_1: player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_2: player1Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) aka ~ballCollidesLeftBorder
                tmpPosCmp_reg_4: ~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE
                */
                //tmpPosCmp_2 = tmpPosCmp_reg_2 && tmpPosCmp_reg_3;
                //tmpPosCmp_3 = tmpPosCmp;

                // Move cmp register 1 to register 2 
                tmpPosCmp_2 = tmpPosCmp_reg_1;
                tmpPosCmp_3 = ~tmpPosCmp_reg_3;
                tmpPosCmp_4 = tmpPosCmp_reg_2 && tmpPosCmp_reg_3;
            end
            COLLISION_CHECK_4: begin
                // TODO what use the addition in this cycle for?

                // Player collision check: player2Pos < ballYPos + BALL_PIXSIZE
                tmpPosCmpOp1 = {{(MAX_POS_LOG + 1 - PLAYER_HEIGHT_LOG){1'b0}}, player2Pos};
                tmpPosCmpOp2 = tmpPosVar_reg_2;

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2: // obsolete
                (readOnly) tmpPosCmp_reg_1: ~(ballXPos > PLAYER_WID) aka ballCollidesLeftBorder
                tmpPosCmp_reg_2: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                tmpPosCmp_reg_3: player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_4: player2Pos < ballYPos + BALL_PIXSIZE

                (readOnly) tmpPosCmp_reg_1: player2Pos < ballYPos + BALL_PIXSIZE
                tmpPosCmp_reg_2: player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) aka ~ballCollidesLeftBorder
                tmpPosCmp_reg_4: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                */
                //tmpPosCmp_4 = tmpPosCmp;

                // Move cmp register 1 to register 2 
                tmpPosCmp_2 = tmpPosCmp_reg_1;
                tmpPosCmp_4 = tmpPosCmp_reg_2 && tmpPosCmp_reg_4;
            end
            COLLISION_CHECK_5: begin
                // TODO what use the addition in this cycle for?

                // Ball X border collision check: ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID))
                tmpPosCmpOp1 = {{(MAX_POS_LOG + 1 - BALL_WIDTH_LOG){1'b0}}, ballXPos};
                tmpPosCmpOp2 = __WIDTH_MIN_BALL_PIXELSIZE_MIN_PLAYER_WID[MAX_POS_LOG:0];

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2: // obsolete
                (readOnly) tmpPosCmp_reg_1: ~(ballXPos > PLAYER_WID) aka ballCollidesLeftBorder
                tmpPosCmp_reg_2: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                tmpPosCmp_reg_3: player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_4: ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)

                (readOnly) tmpPosCmp_reg_1: ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)
                tmpPosCmp_reg_2: player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) aka ~ballCollidesLeftBorder
                tmpPosCmp_reg_4: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                */
                //tmpPosCmp_3 = tmpPosCmp_reg_3 && tmpPosCmp_reg_4;
                //tmpPosCmp_4 = tmpPosCmp;

                tmpPosCmp_2 = tmpPosCmp_reg_1 && tmpPosCmp_reg_2;
            end
            COLLISION_CHECK_6: begin
                // TODO what use the addition in this cycle for?

                // Ball Y border collision check: ~(ballYPos > 0)
                tmpPosCmpOp1 = {(MAX_POS_LOG + 1){1'b0}};
                tmpPosCmpOp2 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2[0]: ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID))
                (readOnly) tmpPosCmp_reg_1: ~(ballXPos > PLAYER_WID) || ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) aka ballCollidesSides
                tmpPosCmp_reg_2: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                tmpPosCmp_reg_3: (~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos)
                tmpPosCmp_reg_4: ballYPos > 0

                (readOnly) tmpPosCmp_reg_1: ballYPos > 0
                tmpPosCmp_reg_2: player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) && ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID) aka ~ballCollidesSides
                tmpPosCmp_reg_4: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                */
                //tmpPosCmp_1 = tmpPosCmp_reg_1 || ~tmpPosCmp_4;
                //tmpPosCmp_3 = tmpPosCmp_reg_3 && ~tmpPosCmp_4;
                //tmpPosCmp_4 = tmpPosCmp;

                tmpPosCmp_3 = tmpPosCmp_reg_1 && tmpPosCmp_reg_3;
                // We can abuse tmpPosVar_reg_2 here as 5th variable!
                tmpPosVar_2[0] = ~tmpPosCmp_reg_1;
            end
            COLLISION_CHECK_7: begin
                // TODO what use the addition in this cycle for?

                // Ball Y border collision check: ~(ballYPos < (HEIGHT - BALL_PIXSIZE))
                tmpPosCmpOp1 = __HEIGHT_MIN_BALL_PIXSIZE[MAX_POS_LOG:0];
                tmpPosCmpOp2 = {{(MAX_POS_LOG + 1 - BALL_HEIGHT_LOG){1'b0}}, ballYPos};

                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2[0]: ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos
                (readOnly) tmpPosCmp_reg_1: ~(ballXPos > PLAYER_WID) || ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) aka ballCollidesSides
                tmpPosCmp_reg_2: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos) || (~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos) aka ballCollidesPlayer
                tmpPosCmp_reg_3: (ballYPos < (HEIGHT - BALL_PIXSIZE))
                tmpPosCmp_reg_4: ~(ballYPos > 0)

                (readOnly) tmpPosCmp_reg_1: (ballYPos < (HEIGHT - BALL_PIXSIZE))
                tmpPosCmp_reg_2: ballYPos > 0
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) && ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID) aka ~ballCollidesSides
                tmpPosCmp_reg_4: (~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)
                */
                //tmpPosCmp_3 = tmpPosCmp;
                //tmpPosCmp_2 = tmpPosCmp_reg_2 || tmpPosCmp_reg_3;
                //tmpPosCmp_4 = ~tmpPosCmp_reg_4;
                // assign nextBallMovesPosX = ballCollidesSides ? ~ballMovesPosX : ballMovesPosX;
                //nextBallMovesPosX = tmpPosCmp_reg_1 ^ ballMovesPosX;

                // Move cmp register 1 to register 2 
                tmpPosCmp_2 = tmpPosCmp_reg_1;
                // assign nextBallMovesPosX = ballCollidesSides ? ~ballMovesPosX : ballMovesPosX;
                nextBallMovesPosX = tmpPosCmp_reg_3 ~^ ballMovesPosX;
                // We can further abuse tmpPosVar_reg_2 here as 5th variable!
                tmpPosVar_2[0] = tmpPosVar_reg_2[0] && tmpPosCmp_reg_2;
            end
            COLLISION_CHECK_8: begin
                // TODO what use the addition in this cycle for?
                // TODO what use the comparison in this cycle for?
                
                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2[0]: (~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos) || ((~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos)) aka ballCollidesPlayer
                (readOnly) tmpPosCmp_reg_1: ~((~(ballXPos > PLAYER_WID) && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos) || (~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)) && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos)) && (~(ballXPos > PLAYER_WID) || ~(ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID))) aka !ballCollidesPlayer && (ballCollidesSides) aka game over
                tmpPosCmp_reg_2: // obsolete
                tmpPosCmp_reg_3: // obsolete
                tmpPosCmp_reg_4: ~(ballYPos > 0) || ~(ballYPos < (HEIGHT - BALL_PIXSIZE)) aka ballCollidesBounceBorders

                (readOnly) tmpPosCmp_reg_1: // obsolete
                tmpPosCmp_reg_2: ballYPos > 0 && (ballYPos < (HEIGHT - BALL_PIXSIZE)) aka ~ballCollidesBounceBorders
                tmpPosCmp_reg_3: (ballXPos > PLAYER_WID) && ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID) aka ~ballCollidesSides
                tmpPosCmp_reg_4: // obsolete
                */
                //tmpPosCmp_1 = ~tmpPosCmp_reg_2 && tmpPosCmp_reg_1;
                //tmpPosCmp_4 = tmpPosCmp_reg_4 || ~tmpPosCmp_reg_3;

                tmpPosCmp_2 = tmpPosCmp_reg_1 && tmpPosCmp_reg_2;
                // We can further further abuse tmpPosVar_reg_2 here as 5th variable!
                tmpPosVar_2[0] = tmpPosVar_reg_2[0] || tmpPosCmp_reg_4;

                // Start calculation for next pos ball x
                // nextBoundedPos #(.UP(1), .POS_LOG_SIZE(BALL_WIDTH_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(WIDTH - BALL_PIXSIZE - PLAYER_WID)) ballXNextBoundedPosUp (.currentPos(ballXPos), .boundedNextPos(nextBallXPosUp));
                // nextBoundedPos #(.UP(0), .POS_LOG_SIZE(BALL_WIDTH_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(PLAYER_WID)) ballXNextBoundedPosDown (.currentPos(ballXPos), .boundedNextPos(nextBallXPosDown));
                dir = ballMovesPosX;
                speed = ballMovesPosX ? BALL_MOVE_SPEED : -BALL_MOVE_SPEED;
                boundary = ballMovesPosX ? WIDTH - BALL_PIXSIZE - PLAYER_WID : PLAYER_WID;
                currentPos = {{(MAX_POS_LOG - BALL_WIDTH_LOG){1'b0}}, ballXPos};
            end
            COLLISION_CHECK_END: begin
                // TODO what use the addition in this cycle for?
                // TODO what use the comparison in this cycle for?
                
                // Register mapping
                /*
                (readOnly) tmpPosVar_reg_1: // obsolete
                tmpPosVar_reg_2: // obsolete
                (readOnly) tmpPosCmp_reg_1: // obsolete
                tmpPosCmp_reg_2: // obsolete
                tmpPosCmp_reg_3: // obsolete
                tmpPosCmp_reg_4: // obsolete
                */
                // assign nextBallMovesPosY = ballCollidesBounceBorders ? ~ballMovesPosY : ballMovesPosY;
                //nextBallMovesPosY = tmpPosCmp_reg_4 ^ ballMovesPosY;

                // assign nextBallMovesPosY = ballCollidesBounceBorders ? ~ballMovesPosY : ballMovesPosY;
                nextBallMovesPosY = tmpPosCmp_reg_2 ~^ ballMovesPosY;

                // Start calculation for next pos ball y
                // nextBoundedPos #(.UP(1), .POS_LOG_SIZE(BALL_HEIGHT_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(HEIGHT - BALL_PIXSIZE)) ballYNextBoundedPosUp (.currentPos(ballYPos), .boundedNextPos(nextBallYPosUp));
                // nextBoundedPos #(.UP(0), .POS_LOG_SIZE(BALL_HEIGHT_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(0)) ballYNextBoundedPosDown (.currentPos(ballYPos), .boundedNextPos(nextBallYPosDown));
                dir = ballMovesPosY;
                speed = ballMovesPosY ? BALL_MOVE_SPEED : -BALL_MOVE_SPEED;
                boundary = ballMovesPosY ? HEIGHT - BALL_PIXSIZE : {(MAX_POS_LOG){1'b0}};
                currentPos = {{(MAX_POS_LOG - BALL_HEIGHT_LOG){1'b0}}, ballYPos};
            end
            CALC_NEXT_POS_BALL_X: begin
                nextBallXPos = boundedNextPos[BALL_WIDTH_LOG-1:0];

                // Start calculation for next pos player1
                // nextBoundedPos #(.UP(1), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(HEIGHT - PLAYER_LEN)) player1NextBoundedPosUp (.currentPos(player1Pos), .boundedNextPos(nextPlayer1PosUp));
                // nextBoundedPos #(.UP(0), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(0)) player1NextBoundedPosDown (.currentPos(player1Pos), .boundedNextPos(nextPlayer1PosDown));
                dir = player1YUp;
                speed = player1YUp ? PLAYER_MOVE_SPEED : -PLAYER_MOVE_SPEED;
                boundary = player1YUp ? HEIGHT - PLAYER_LEN : {(MAX_POS_LOG){1'b0}};
                currentPos = {{(MAX_POS_LOG - PLAYER_HEIGHT_LOG){1'b0}}, player1Pos};
            end
            CALC_NEXT_POS_BALL_Y: begin
                nextBallYPos = boundedNextPos[BALL_HEIGHT_LOG-1:0];

                // Start calculation for next pos player2
                // nextBoundedPos #(.UP(1), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(HEIGHT - PLAYER_LEN)) player2NextBoundedPosUp (.currentPos(player2Pos), .boundedNextPos(nextPlayer2PosUp));
                // nextBoundedPos #(.UP(0), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(0)) player2NextBoundedPosDown (.currentPos(player2Pos), .boundedNextPos(nextPlayer2PosDown));
                dir = player2YUp;
                speed = player2YUp ? PLAYER_MOVE_SPEED : -PLAYER_MOVE_SPEED;
                boundary = player2YUp ? HEIGHT - PLAYER_LEN : {(MAX_POS_LOG){1'b0}};
                currentPos = {{(MAX_POS_LOG - PLAYER_HEIGHT_LOG){1'b0}}, player2Pos};
            end
            CALC_NEXT_POS_PLAYER_1: begin
                nextPlayer1Pos = player1YUp == player1YDown ? player1Pos : boundedNextPos[PLAYER_HEIGHT_LOG-1:0];

            end
            CALC_NEXT_POS_PLAYER_2: begin
                nextPlayer2Pos = player2YUp == player2YDown ? player2Pos : boundedNextPos[PLAYER_HEIGHT_LOG-1:0];
            end
            SCORE_END: begin
                // Additional Game over changes
                nextPlayer1Pos = PLAYER_START_POS;
                nextPlayer2Pos = PLAYER_START_POS;
                nextBallXPos = ballMovesPosX ? BALL_START_POS_X_PLAYER_2 : BALL_START_POS_X_PLAYER_1;
            end
        endcase
    end

    // Writeback
    always_ff @(posedge pixIf_CLK) begin
        tmpPosVar_reg_1 <= tmpPosVar_1;
        tmpPosVar_reg_2 <= tmpPosVar_2;
        tmpPosCmp_reg_1 <= tmpPosCmp_1;
        tmpPosCmp_reg_2 <= tmpPosCmp_2;
        tmpPosCmp_reg_3 <= tmpPosCmp_3;
        tmpPosCmp_reg_4 <= tmpPosCmp_4;
        ballMovesPosX <= nextBallMovesPosX;
        ballMovesPosY <= nextBallMovesPosY;
        player1Pos <= nextPlayer1Pos;
        player2Pos <= nextPlayer2Pos;
        ballXPos <= nextBallXPos;
        ballYPos <= nextBallYPos;
    end

    // Set initial values
    initial begin
        fsmState = IDLE;
        player1Pos = PLAYER_START_POS;
        player2Pos = PLAYER_START_POS;
        ballXPos = BALL_START_POS_X_PLAYER_1;
        ballYPos = BALL_START_POS_Y;
        ballMovesPosX = 0;
        ballMovesPosY = 0;
        // Other registers are considered as dont care!
    end

    always_ff @(posedge pixIf_CLK) begin
        // Make moves only after the frame is done drawing!
        if (pixIf_NEXT_FRAME) begin
            fsmState <= COLLISION_CHECK_START;
        end else begin
            fsmState <= next_fsmState;
        end
    end

endmodule


// Lets start simple pipelined implementation without FSM logic
module nextBoundedPosPipelined_ #(
    parameter POS_LOG_SIZE
)(
    input logic CLK,
    input logic dir,
    input logic [POS_LOG_SIZE-1:0] speed,
    input logic [POS_LOG_SIZE-1:0] boundary,
    input logic [POS_LOG_SIZE-1:0] currentPos,
    output logic [POS_LOG_SIZE-1:0] boundedNextPos
);

    // pipeline register
    logic dir_reg_1, dir_reg_2;
    logic [POS_LOG_SIZE-1:0] speed_reg, currentPos_reg, boundary_reg_1, boundary_reg_2;
    logic [POS_LOG_SIZE:0] unboundedNextPos_reg, unboundedNextPos;

    assign unboundedNextPos = currentPos_reg + speed_reg;
    assign boundedNextPos = (dir_reg_2 ? unboundedNextPos_reg : {1'b0, boundary_reg_2}) >= (dir_reg_2 ? {1'b0, boundary_reg_2} : unboundedNextPos_reg)? boundary_reg_2 : unboundedNextPos_reg[POS_LOG_SIZE-1:0];

    always_ff @(posedge CLK) begin
        currentPos_reg <= currentPos;
        speed_reg <= speed;
        dir_reg_1 <= dir;
        dir_reg_2 <= dir_reg_1;
        boundary_reg_1 <= boundary;
        boundary_reg_2 <= boundary_reg_1;
        unboundedNextPos_reg <= unboundedNextPos;
    end
endmodule