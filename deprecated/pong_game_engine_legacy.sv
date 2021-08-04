/*
    Backup of working game engine before trying resource usage and timing improvements with FSMs
*/
module pong_game_engine_legacy
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

    // Game variables: Coordinate system starts at upperleft with (0,0)
    logic [PLAYER_HEIGHT_LOG-1:0] nextPlayer1PosUp, nextPlayer1PosDown, nextPlayer2PosUp, nextPlayer2PosDown;
    logic [BALL_WIDTH_LOG-1:0] nextBallXPosUp, nextBallXPosDown;
    logic [BALL_HEIGHT_LOG-1:0] nextBallYPosUp, nextBallYPosDown;
    logic ballMovesPosX, ballMovesPosY, nextBallMovesPosX, nextBallMovesPosY;

    // Set initial values
    initial begin
        player1Pos = PLAYER_START_POS;
        player2Pos = PLAYER_START_POS;
        ballXPos = BALL_START_POS_X_PLAYER_1;
        ballYPos = BALL_START_POS_Y;
        ballMovesPosX = 0;
        ballMovesPosY = 0;
    end

    // Collision checks
    // collision with top or bottom border -> no problem
    logic ballCollidesBounceBorders;
    // correct bounce
    logic ballCollidesPlayer;
    logic ballCollidesSides;
    // Game over states
    logic ballCollidesLeftBorder;
    logic ballCollidesRightBorder;

    assign ballCollidesPlayer = (ballCollidesLeftBorder && player1Pos < ballYPos + BALL_PIXSIZE && player1Pos + PLAYER_LEN > ballYPos) ||
                                (ballCollidesRightBorder && player2Pos < ballYPos + BALL_PIXSIZE && player2Pos + PLAYER_LEN > ballYPos);

    assign ballCollidesBounceBorders = ballYPos == 0 || (ballYPos == (HEIGHT - BALL_PIXSIZE));
    assign ballCollidesLeftBorder = ballXPos == PLAYER_WID;
    assign ballCollidesRightBorder = ballXPos == (WIDTH - BALL_PIXSIZE - PLAYER_WID);

    assign ballCollidesSides = ballCollidesLeftBorder || ballCollidesRightBorder;

    assign nextBallMovesPosX = ballCollidesSides ? ~ballMovesPosX : ballMovesPosX;
    assign nextBallMovesPosY = ballCollidesBounceBorders ? ~ballMovesPosY : ballMovesPosY;

    // Bounded player moves
    nextBoundedPos #(.UP(1), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(HEIGHT - PLAYER_LEN)) player1NextBoundedPosUp (.currentPos(player1Pos), .boundedNextPos(nextPlayer1PosUp));
    nextBoundedPos #(.UP(0), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(0)) player1NextBoundedPosDown (.currentPos(player1Pos), .boundedNextPos(nextPlayer1PosDown));
    nextBoundedPos #(.UP(1), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(HEIGHT - PLAYER_LEN)) player2NextBoundedPosUp (.currentPos(player2Pos), .boundedNextPos(nextPlayer2PosUp));
    nextBoundedPos #(.UP(0), .POS_LOG_SIZE(PLAYER_HEIGHT_LOG), .SPEED(PLAYER_MOVE_SPEED), .BOUNDARY(0)) player2NextBoundedPosDown (.currentPos(player2Pos), .boundedNextPos(nextPlayer2PosDown));
    // Bounded ball moves
    nextBoundedPos #(.UP(1), .POS_LOG_SIZE(BALL_WIDTH_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(WIDTH - BALL_PIXSIZE - PLAYER_WID)) ballXNextBoundedPosUp (.currentPos(ballXPos), .boundedNextPos(nextBallXPosUp));
    nextBoundedPos #(.UP(0), .POS_LOG_SIZE(BALL_WIDTH_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(PLAYER_WID)) ballXNextBoundedPosDown (.currentPos(ballXPos), .boundedNextPos(nextBallXPosDown));
    nextBoundedPos #(.UP(1), .POS_LOG_SIZE(BALL_HEIGHT_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(HEIGHT - BALL_PIXSIZE)) ballYNextBoundedPosUp (.currentPos(ballYPos), .boundedNextPos(nextBallYPosUp));
    nextBoundedPos #(.UP(0), .POS_LOG_SIZE(BALL_HEIGHT_LOG), .SPEED(BALL_MOVE_SPEED), .BOUNDARY(0)) ballYNextBoundedPosDown (.currentPos(ballYPos), .boundedNextPos(nextBallYPosDown));

    always_ff @(posedge pixIf_CLK) begin
        // Make moves only after the frame is done drawing!
        if (pixIf_NEXT_FRAME) begin
            if (!ballCollidesPlayer && ballCollidesSides) begin
                // Ball was not catched!
                // Reset positions
                player1Pos <= PLAYER_START_POS;
                player2Pos <= PLAYER_START_POS;
                // Reset position so that the player that won is next and has some time to react
                ballXPos <= ballMovesPosX ? BALL_START_POS_X_PLAYER_1 : BALL_START_POS_X_PLAYER_2;
                // Reuse last Y pos to have a new start! and not always the same deterministic shit!
                //ballYPos <= BALL_START_POS_Y;
                // Player X failed -> let the other player start next
                ballMovesPosX <= ~ballMovesPosX;
                // Also do invert Y direction for more pseudo randomness 
                //ballMovesPosY <= ~ballMovesPosY;
                //TODO introduce and update score?
            end else begin
                ballXPos <= nextBallMovesPosX ? nextBallXPosUp : nextBallXPosDown;
                ballYPos <= nextBallMovesPosY ? nextBallYPosUp : nextBallYPosDown;
                ballMovesPosX <= nextBallMovesPosX;
                ballMovesPosY <= nextBallMovesPosY;
                player1Pos <= player1YUp == player1YDown ? player1Pos : (player1YUp ? nextPlayer1PosUp : nextPlayer1PosDown);
                player2Pos <= player2YUp == player2YDown ? player2Pos : (player2YUp ? nextPlayer2PosUp : nextPlayer2PosDown);
            end
        end
    end

endmodule

module nextBoundedPos #(
    parameter UP,
    parameter POS_LOG_SIZE,
    parameter SPEED,
    parameter BOUNDARY
)(
    input logic [POS_LOG_SIZE-1:0] currentPos,
    output logic [POS_LOG_SIZE-1:0] boundedNextPos
);

    generate
        localparam BOUNDARY_UP_LIM = BOUNDARY - SPEED;
        localparam BOUNDARY_DOWN_LIM = BOUNDARY + SPEED;
        if (UP) begin
            assign boundedNextPos = currentPos >= BOUNDARY_UP_LIM[POS_LOG_SIZE-1:0] ? BOUNDARY[POS_LOG_SIZE-1:0] : currentPos + SPEED[POS_LOG_SIZE-1:0];
        end else begin 
            assign boundedNextPos = BOUNDARY_DOWN_LIM[POS_LOG_SIZE-1:0] >= currentPos ? BOUNDARY[POS_LOG_SIZE-1:0] : currentPos + (-SPEED[POS_LOG_SIZE-1:0]);
        end
    endgenerate

endmodule

