`ifdef USE_INTERFACES
interface vga_bus;
    logic vga_h_sync;
    logic vga_v_sync;
    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;

    modport control (
        output vga_r, vga_g, vga_b, vga_h_sync, vga_v_sync
    );

    modport exec (
        input vga_r, vga_g, vga_b, vga_h_sync, vga_v_sync
    );
endinterface
`endif