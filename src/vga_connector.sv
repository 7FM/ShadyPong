module vga_connector 
#(
    parameter WIDTH,
    parameter HEIGHT,
    parameter PIPELINE_STAGES,
    parameter HSYNC_FPORCH,
    parameter HSYNC_PULSE,
    parameter HSYNC_BPORCH,
    parameter VSYNC_FPORCH,
    parameter VSYNC_PULSE,
    parameter VSYNC_BPORCH,
    parameter HSYNC_POLARITY_NEG,
    parameter VSYNC_POLARITY_NEG,
    parameter H_CNT_WID,
    parameter V_CNT_WID
)(
    input logic CLK,
`ifdef USE_INTERFACES
    pixel_bus.consumer pixIf,
    vga_bus.control vgaIf
`else
    // Pixel bus
    output logic pixIf_NEXT_FRAME,
    output logic pixIf_H_BLANKING,
    output logic [H_CNT_WID-1:0] pixIf_H_CNT,
    output logic [V_CNT_WID-1:0] pixIf_next_V_CNT,
    input logic [3:0] pixIf_r,
    input logic [3:0] pixIf_g,
    input logic [3:0] pixIf_b,
    // VGA bus
    output logic vgaIf_vga_h_sync,
    output logic vgaIf_vga_v_sync,
    output logic [3:0] vgaIf_vga_r,
    output logic [3:0] vgaIf_vga_g,
    output logic [3:0] vgaIf_vga_b
`endif
);

    localparam H_SIZE = WIDTH + HSYNC_FPORCH + HSYNC_PULSE + HSYNC_BPORCH;
    localparam LOG_H_SIZE = $clog2(H_SIZE);
    localparam V_SIZE = HEIGHT + VSYNC_FPORCH + VSYNC_PULSE + VSYNC_BPORCH;
    localparam LOG_V_SIZE = $clog2(V_SIZE);

    logic [LOG_H_SIZE-1:0] h_cnt, h_cnt_inc;
    logic [LOG_V_SIZE-1:0] v_cnt, v_cnt_inc, next_v_cnt;

    // The minimum delay to get an pixel is 3 cycles, but h_sync and v_sync are already exposed with an delay of 2 -> we need another buffer stage
    logic [PIPELINE_STAGES+1:0] h_sync_reg, v_sync_reg;
    //logic [PIPELINE_STAGES:0] h_sync_reg, v_sync_reg;
    logic h_sync_, v_sync_;
    logic [PIPELINE_STAGES:0] blanking;
    logic isInBlanking, hBlanking;

    logic [3:0] vga_r_reg, vga_g_reg, vga_b_reg;

    // Connect busses
`ifdef USE_INTERFACES
    // Dummy intermediates
    logic vgaIf_vga_h_sync, vgaIf_vga_v_sync;
    logic [3:0] vgaIf_vga_r, vgaIf_vga_g, vgaIf_vga_b;
    logic pixIf_NEXT_FRAME, pixIf_H_BLANKING;
    logic [H_CNT_WID-1:0] pixIf_H_CNT;
    logic [V_CNT_WID-1:0] pixIf_next_V_CNT;
    logic [3:0] pixIf_r, pixIf_g, pixIf_b;
    assign {vgaIf.vga_h_sync, vgaIf.vga_v_sync} = {vgaIf_vga_h_sync, vgaIf_vga_v_sync};
    assign {vgaIf.vga_r, vgaIf.vga_g, vgaIf.vga_b} = {vgaIf_vga_r, vgaIf_vga_g, vgaIf_vga_b};
    assign {pixIf.NEXT_FRAME, pixIf.H_BLANKING} = {pixIf_NEXT_FRAME, pixIf_H_BLANKING};
    assign {pixIf.H_CNT, pixIf.next_V_CNT} = {pixIf_H_CNT, pixIf_next_V_CNT};
    assign {pixIf_r, pixIf_g, pixIf_b} = {pixIf.r, pixIf.g, pixIf.b};
`endif

    assign {vgaIf_vga_h_sync, vgaIf_vga_v_sync} = {h_sync_reg[PIPELINE_STAGES+1], v_sync_reg[PIPELINE_STAGES+1]};
    //assign {vgaIf_vga_h_sync, vgaIf_vga_v_sync} = {h_sync_reg[PIPELINE_STAGES], v_sync_reg[PIPELINE_STAGES]};
    assign {vgaIf_vga_r, vgaIf_vga_g, vgaIf_vga_b} = {vga_r_reg, vga_g_reg, vga_b_reg};

    assign pixIf_H_CNT = h_cnt[H_CNT_WID-1:0];
    assign pixIf_next_V_CNT = next_v_cnt[V_CNT_WID-1:0];
    // Only request pixels when not in blanking and after stall cycles
    assign pixIf_NEXT_FRAME = v_cnt == HEIGHT-1 && h_cnt == WIDTH;
    assign pixIf_H_BLANKING = hBlanking;

    // Combinatorial logic
    generate
        //TODO this could be further pipelined / optimized
        if (HSYNC_POLARITY_NEG) begin
            assign h_sync_ = (h_cnt < WIDTH + HSYNC_FPORCH || h_cnt >= WIDTH + HSYNC_FPORCH + HSYNC_PULSE);
        end else begin
            assign h_sync_ = (h_cnt >= WIDTH + HSYNC_FPORCH && h_cnt < WIDTH + HSYNC_FPORCH + HSYNC_PULSE);
        end
        if (VSYNC_POLARITY_NEG) begin
            assign v_sync_ = (v_cnt < HEIGHT + VSYNC_FPORCH || v_cnt >= HEIGHT + VSYNC_FPORCH + VSYNC_PULSE);
        end else begin
            assign v_sync_ = (v_cnt >= HEIGHT + VSYNC_FPORCH && v_cnt < HEIGHT + VSYNC_FPORCH + VSYNC_PULSE);
        end
    endgenerate

    logic lastHorizClk, lastVertClk;
    assign lastHorizClk = h_cnt == H_SIZE - 1;
    assign lastVertClk = v_cnt == V_SIZE - 1;
    assign h_cnt_inc = (lastHorizClk ? 0 : h_cnt + 1);
    assign next_v_cnt = (lastVertClk ? 0 : v_cnt + 1);
    assign v_cnt_inc = lastHorizClk ? next_v_cnt : v_cnt;

    assign hBlanking = h_cnt >= WIDTH;
    assign isInBlanking = hBlanking || v_cnt >= HEIGHT;

    // Initialize registers
    initial begin
        {h_cnt, v_cnt} = {LOG_H_SIZE+LOG_V_SIZE{1'b0}};
        {vga_r_reg, vga_g_reg, vga_b_reg} = {4*3{1'b0}};
        h_sync_reg = {PIPELINE_STAGES+2{{HSYNC_POLARITY_NEG[0]}}};
        v_sync_reg = {PIPELINE_STAGES+2{{VSYNC_POLARITY_NEG[0]}}};
        //{h_sync_reg, v_sync_reg} = {PIPELINE_STAGES+1{{2{SYNC_POLARITY_NEG[0]}}}};
        blanking = {PIPELINE_STAGES+1{1'b1}};
    end

    always_ff @(posedge CLK) begin
        h_cnt <= h_cnt_inc;
        v_cnt <= v_cnt_inc;
        h_sync_reg <= {h_sync_reg[PIPELINE_STAGES:0], h_sync_};
        v_sync_reg <= {v_sync_reg[PIPELINE_STAGES:0], v_sync_};
    end

    // Propergate pipelines
    generate
        if (PIPELINE_STAGES) begin
            always_ff @(posedge CLK) begin
                blanking <= {blanking[PIPELINE_STAGES-1:0], isInBlanking};
                //h_sync_reg <= {h_sync_reg[PIPELINE_STAGES-1:0], h_sync_};
                //v_sync_reg <= {v_sync_reg[PIPELINE_STAGES-1:0], v_sync_};
            end
        end else begin
            always_ff @(posedge CLK) begin
                blanking <= isInBlanking;
                //h_sync_reg <= h_sync_;
                //v_sync_reg <= v_sync_;
            end
        end
    endgenerate

    always_ff @(posedge CLK) begin
        // During Blanking we want the output voltage to be 0V
        if (blanking[PIPELINE_STAGES]) begin
            {vga_r_reg, vga_g_reg, vga_b_reg} <= {4*3{1'b0}};
        end else begin
            // Else only apply changes if signal is valid?
            {vga_r_reg, vga_g_reg, vga_b_reg} <= {pixIf_r, pixIf_g, pixIf_b};
        end
    end

endmodule
