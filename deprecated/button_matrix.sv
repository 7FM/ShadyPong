module button_matrix
#(
    parameter ROWS=4,
    parameter COLS=4
)(
    input CLK,
    output logic [ROWS-1:0] rows,
    //TODO these inputs require a pull down!
    input logic [COLS-1:0] cols,
//    output logic [ROWS-1:0][COLS-1:0] buttonStates
    output logic [ROWS*COLS-1:0] buttonStates
);

    localparam ROW_IDX_LOG = $clog2(ROWS);

    //logic [ROWS-1:0][COLS-1:0] buttonStatesMat;
    logic [ROWS*COLS-1:0] buttonStatesMat;
    logic [ROW_IDX_LOG-1:0] rowIdx, rowIdxInc;

    // Generate tristate outputs with only one being active at any time
    generate
        genvar i;
        for (i=0; i < ROWS; i = i + 1)
            assign rows[i] = i == rowIdx ? 1'b1 : 1'bz;
    endgenerate

    assign buttonStates = buttonStatesMat;
    localparam ROWS_MAX_IDX = ROWS - 1;
    assign rowIdxInc = rowIdx < ROWS_MAX_IDX[ROW_IDX_LOG-1:0] ? rowIdx + 1 : 0; 

    initial begin
        buttonStatesMat = {COLS*ROWS{1'b0}};
        rowIdx = 0;
    end

    always_ff @(posedge CLK) begin
        rowIdx <= rowIdxInc;
        //buttonStatesMat[rowIdx] <= cols;
    end

    generate
        genvar j;
        for (j=0; j < ROWS; j = j + 1) begin 
            always_ff @(posedge CLK) begin
                buttonStatesMat[(j+1)*COLS-1:j*COLS] <= j == rowIdx ? cols : buttonStatesMat[(j+1)*COLS-1:j*COLS];
            end
        end
    endgenerate

endmodule