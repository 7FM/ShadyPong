// Lets start simple pipelined implementation without FSM logic
module nextBoundedPosPipelined #(
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

    // signExt
    assign unboundedNextPos = currentPos_reg + {speed_reg[POS_LOG_SIZE-1], speed_reg};
    assign boundedNextPos = signed'(dir_reg_2 ? unboundedNextPos_reg : {1'b0, boundary_reg_2}) >= signed'(dir_reg_2 ? {1'b0, boundary_reg_2} : unboundedNextPos_reg) ? boundary_reg_2 : unboundedNextPos_reg[POS_LOG_SIZE-1:0];

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
