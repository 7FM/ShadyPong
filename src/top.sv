`include "../config.sv"
`include "../vga_timings.sv"

module top (
    input logic CLK,
    output logic vga_h_sync,
    output logic vga_v_sync,
    output logic [3:0] vga_R, 
    output logic [3:0] vga_G,
    output logic [3:0] vga_B,
    input logic [3:0] btns
);
    logic pixelCLK;

    // User input
    logic player1YUp, player1YDown, player2YUp, player2YDown;

    /*
    assign player1YUp = 1'b1;
    assign player1YDown = 1'b0;
    assign player2YUp = 1'b0;
    assign player2YDown = 1'b1;
    */
    assign {player1YUp, player1YDown, player2YUp, player2YDown} = btns;

`ifndef RUN_SIM
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(`PLL_CLK_DIVR),
        .DIVF(`PLL_CLK_DIVF),
        .DIVQ(`PLL_CLK_DIVQ),
        .FILTER_RANGE(`PLL_CLK_FILTER_RANGE)
    ) clkGen (
        .RESETB(`PLL_CLK_RESETB),
        .BYPASS(`PLL_CLK_BYPASS),
        .PACKAGEPIN(CLK),
        .PLLOUTCORE(pixelCLK)
    );
`else
    assign pixelCLK = CLK;
`endif
    localparam WIDTH=`WIDTH;
    localparam HSYNC_FPORCH=`HSYNC_FPORCH;
    localparam HSYNC_PULSE=`HSYNC_PULSE;
    localparam HSYNC_BPORCH=`HSYNC_BPORCH;

    localparam HEIGHT=`HEIGHT;
    localparam VSYNC_FPORCH=`VSYNC_FPORCH;
    localparam VSYNC_PULSE=`VSYNC_PULSE;
    localparam VSYNC_BPORCH=`VSYNC_BPORCH;

    localparam HSYNC_POLARITY_NEG=`HSYNC_POLARITY_NEG;
    localparam VSYNC_POLARITY_NEG=`VSYNC_POLARITY_NEG;

    localparam BUTTON_LOW_ACTIVE = 1;

    // Design settings
    localparam PIPELINE_STAGES=0;

    // Visual parameters
    // TODO adjust on frame rate & display size
    localparam BALL_PIXSIZE=5;
    localparam PLAYER_LEN=50;
    localparam PLAYER_WID=8;
    localparam PLAYER_MOVE_SPEED=4;
    localparam BALL_MOVE_SPEED=4;

    localparam BALL_COL_R=4'b1111; 
    localparam BALL_COL_G=4'd0; 
    localparam BALL_COL_B=4'd0;
    localparam PLAYER_1_COL_R=4'd0; 
    localparam PLAYER_1_COL_G=4'b1111; 
    localparam PLAYER_1_COL_B=4'd0;
    localparam PLAYER_2_COL_R=4'd0; 
    localparam PLAYER_2_COL_G=4'd0; 
    localparam PLAYER_2_COL_B=4'b1111;
    localparam BG_COL_R=4'd1;
    localparam BG_COL_G=4'd2; 
    localparam BG_COL_B=4'd3;

    // For the pixels only the visible area needs to be considered
    localparam LOG_H_SIZE = $clog2(WIDTH);
    localparam LOG_V_SIZE = $clog2(HEIGHT);

`ifdef USE_INTERFACES
    vga_bus vgaBus();
    assign vga_h_sync = vgaBus.vga_h_sync;
    assign vga_v_sync = vgaBus.vga_v_sync;
    assign vga_R = vgaBus.vga_r;
    assign vga_G = vgaBus.vga_g;
    assign vga_B = vgaBus.vga_b;

    pixel_bus #(.H_CNT_WID(LOG_H_SIZE), .V_CNT_WID(LOG_V_SIZE)) pixelBus();
`else
    logic pixelBus_NEXT_FRAME, pixelBus_H_BLANKING;
    logic [LOG_H_SIZE-1:0] pixelBus_H_CNT;
    logic [LOG_V_SIZE-1:0] pixelBus_next_V_CNT;
    logic [3:0] pixelBus_r;
    logic [3:0] pixelBus_g;
    logic [3:0] pixelBus_b;
`endif

`ifdef DUMMY_PIXEL_ENGINE
    dummy_pixel_engine #(.H_CNT_WID(LOG_H_SIZE), .V_CNT_WID(LOG_V_SIZE)) pixelCreator (
`ifdef USE_INTERFACES
        .pixIf(pixelBus.producer)
`else
        .pixIf_NEXT_FRAME(pixelBus_NEXT_FRAME),
        .pixIf_H_BLANKING(pixelBus_H_BLANKING),
        .pixIf_H_CNT(pixelBus_H_CNT),
        .pixIf_next_V_CNT(pixelBus_next_V_CNT),
        .pixIf_r(pixelBus_r),
        .pixIf_g(pixelBus_g),
        .pixIf_b(pixelBus_b)
`endif
    );
`else
    pong_pixel_engine #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .H_CNT_WID(LOG_H_SIZE), .V_CNT_WID(LOG_V_SIZE),
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .BUTTON_LOW_ACTIVE(BUTTON_LOW_ACTIVE),
        .BALL_PIXSIZE(BALL_PIXSIZE),
        .PLAYER_LEN(PLAYER_LEN),
        .PLAYER_WID(PLAYER_WID),
        .PLAYER_MOVE_SPEED(PLAYER_MOVE_SPEED),
        .BALL_MOVE_SPEED(BALL_MOVE_SPEED),
        .BALL_COL_R(BALL_COL_R), .BALL_COL_G(BALL_COL_G), .BALL_COL_B(BALL_COL_B),
        .PLAYER_1_COL_R(PLAYER_1_COL_R), .PLAYER_1_COL_G(PLAYER_1_COL_G), .PLAYER_1_COL_B(PLAYER_1_COL_B),
        .PLAYER_2_COL_R(PLAYER_2_COL_R), .PLAYER_2_COL_G(PLAYER_2_COL_G), .PLAYER_2_COL_B(PLAYER_2_COL_B),
        .BG_COL_R(BG_COL_R), .BG_COL_G(BG_COL_G), .BG_COL_B(BG_COL_B)
    ) pixelCreator (
        .pixIf_CLK(pixelCLK),
`ifdef USE_INTERFACES
        .pixIf(pixelBus.producer),
`else
        .pixIf_NEXT_FRAME(pixelBus_NEXT_FRAME),
        .pixIf_H_BLANKING(pixelBus_H_BLANKING),
        .pixIf_H_CNT(pixelBus_H_CNT),
        .pixIf_next_V_CNT(pixelBus_next_V_CNT),
        .pixIf_r(pixelBus_r),
        .pixIf_g(pixelBus_g),
        .pixIf_b(pixelBus_b),
`endif
        .player1YUp(player1YUp), 
        .player1YDown(player1YDown),
        .player2YUp(player2YUp), 
        .player2YDown(player2YDown)
    );
`endif

    vga_connector #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .HSYNC_FPORCH(HSYNC_FPORCH),
        .HSYNC_PULSE(HSYNC_PULSE),
        .HSYNC_BPORCH(HSYNC_BPORCH),
        .VSYNC_FPORCH(VSYNC_FPORCH),
        .VSYNC_PULSE(VSYNC_PULSE),
        .VSYNC_BPORCH(VSYNC_BPORCH),
        .HSYNC_POLARITY_NEG(HSYNC_POLARITY_NEG),
        .VSYNC_POLARITY_NEG(VSYNC_POLARITY_NEG),
        .H_CNT_WID(LOG_H_SIZE),
        .V_CNT_WID(LOG_V_SIZE)
    ) vgaController(
        .CLK(pixelCLK),
`ifdef USE_INTERFACES
        .pixIf(pixelBus.consumer),
        .vgaIf(vgaBus.control)
`else
        .pixIf_NEXT_FRAME(pixelBus_NEXT_FRAME),
        .pixIf_H_BLANKING(pixelBus_H_BLANKING),
        .pixIf_H_CNT(pixelBus_H_CNT),
        .pixIf_next_V_CNT(pixelBus_next_V_CNT),
        .pixIf_r(pixelBus_r),
        .pixIf_g(pixelBus_g),
        .pixIf_b(pixelBus_b),
        .vgaIf_vga_r(vga_R),
        .vgaIf_vga_g(vga_G),
        .vgaIf_vga_b(vga_B),
        .vgaIf_vga_h_sync(vga_h_sync),
        .vgaIf_vga_v_sync(vga_v_sync)
`endif
    );

endmodule
