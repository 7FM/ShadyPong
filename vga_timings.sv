`ifndef VGA_TIMINGS_SV
`define VGA_TIMINGS_SV

// Thanks to: http://www.tinyvga.com/vga-timing

`ifdef VGA_640_350_70_Hz
    // VGA parameters: 640x350 @ 70Hz
    `define FPS 70
    `define WIDTH 640
    `define HSYNC_FPORCH 16
    `define HSYNC_PULSE 96
    `define HSYNC_BPORCH 48
    `define HSYNC_POLARITY_NEG 0

    `define HEIGHT 350
    `define VSYNC_FPORCH 37
    `define VSYNC_PULSE 2
    `define VSYNC_BPORCH 60
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 25.175Mhz
    // F_PLLOUT:   25.125 MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1000010
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_350_85_Hz
    // VGA parameters: 640x350 @ 85Hz
    `define FPS 85
    `define WIDTH 640
    `define HSYNC_FPORCH 32
    `define HSYNC_PULSE 64
    `define HSYNC_BPORCH 96
    `define HSYNC_POLARITY_NEG 0

    `define HEIGHT 350
    `define VSYNC_FPORCH 32
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 60
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 31.5Mhz
    // F_PLLOUT:   31.5   MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1010011
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_400_70_Hz
    // VGA parameters: 640x400 @ 70Hz
    `define FPS 70
    `define WIDTH 640
    `define HSYNC_FPORCH 16
    `define HSYNC_PULSE 96
    `define HSYNC_BPORCH 48
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 400
    `define VSYNC_FPORCH 12
    `define VSYNC_PULSE 2
    `define VSYNC_BPORCH 35
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 25.175Mhz
    // F_PLLOUT:   25.125 MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1000010
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_400_85_Hz
    // VGA parameters: 640x400 @ 85Hz
    `define FPS 85
    `define WIDTH 640
    `define HSYNC_FPORCH 32
    `define HSYNC_PULSE 64
    `define HSYNC_BPORCH 96
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 400
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 41
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 31.5Mhz
    // F_PLLOUT:   31.5   MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1010011
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_480_60_Hz
    // VGA parameters: 640x480 @ 60Hz
    `define FPS 60
    `define WIDTH 640
    `define HSYNC_FPORCH 16
    `define HSYNC_PULSE 96
    `define HSYNC_BPORCH 48
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 480
    `define VSYNC_FPORCH 10
    `define VSYNC_PULSE 2
    `define VSYNC_BPORCH 33
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 25.175Mhz
    // F_PLLOUT:   25.125 MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1000010
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_480_73_Hz
    // VGA parameters: 640x480 @ 73Hz
    `define FPS 73
    `define WIDTH 640
    `define HSYNC_FPORCH 24
    `define HSYNC_PULSE 40
    `define HSYNC_BPORCH 128
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 480
    `define VSYNC_FPORCH 9
    `define VSYNC_PULSE 2
    `define VSYNC_BPORCH 29
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 31.5Mhz
    // F_PLLOUT:   31.5   MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1010011
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_480_75_Hz
    // VGA parameters: 640x480 @ 75Hz
    `define FPS 75
    `define WIDTH 640
    `define HSYNC_FPORCH 16
    `define HSYNC_PULSE 64
    `define HSYNC_BPORCH 120
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 480
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 16
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 31.5Mhz
    // F_PLLOUT:   31.5   MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b1010011
    `define PLL_CLK_DIVQ 3'b101
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_480_85_Hz
    // VGA parameters: 640x480 @ 85Hz
    `define FPS 85
    `define WIDTH 640
    `define HSYNC_FPORCH 56
    `define HSYNC_PULSE 56
    `define HSYNC_BPORCH 80
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 480
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 25
    `define VSYNC_POLARITY_NEG 1

    // $icepll -i 12MHz -o 36Mhz
    // F_PLLOUT:   36     MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0101111
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_640_480_100_Hz
    // VGA parameters: 640x480 @ 100Hz
    `define FPS 100
    `define WIDTH 640
    `define HSYNC_FPORCH 40
    `define HSYNC_PULSE 64
    `define HSYNC_BPORCH 104
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 480
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 25
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 43.16Mhz
    // F_PLLOUT:   43.5   MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0111001
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_720_400_85_Hz
    // VGA parameters: 720x400 @ 85Hz
    `define FPS 85
    `define WIDTH 720
    `define HSYNC_FPORCH 36
    `define HSYNC_PULSE 72
    `define HSYNC_BPORCH 108
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 400
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 42
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 35.5Mhz
    // F_PLLOUT:   35.25  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0101110
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_768_576_60_Hz
    // VGA parameters: 768x576 @ 60Hz
    `define FPS 60
    `define WIDTH 768
    `define HSYNC_FPORCH 24
    `define HSYNC_PULSE 80
    `define HSYNC_BPORCH 104
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 576
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 17
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 34.96Mhz
    // F_PLLOUT:   35.25  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0101110
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_768_576_72_Hz
    // VGA parameters: 768x576 @ 72Hz
    `define FPS 72
    `define WIDTH 768
    `define HSYNC_FPORCH 32
    `define HSYNC_PULSE 80
    `define HSYNC_BPORCH 112
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 576
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 21
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 42.93Mhz
    // F_PLLOUT:   42.75  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0111000
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_768_576_75_Hz
    // VGA parameters: 768x576 @ 75Hz
    `define FPS 75
    `define WIDTH 768
    `define HSYNC_FPORCH 40
    `define HSYNC_PULSE 80
    `define HSYNC_BPORCH 120
    `define HSYNC_POLARITY_NEG 1

    `define HEIGHT 576
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 3
    `define VSYNC_BPORCH 22
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 45.51Mhz
    // F_PLLOUT:   45.75  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0111100
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_800_600_56_Hz
    // VGA parameters: 800x600 @ 56Hz
    `define FPS 56
    `define WIDTH 800
    `define HSYNC_FPORCH 24
    `define HSYNC_PULSE 72
    `define HSYNC_BPORCH 128
    `define HSYNC_POLARITY_NEG 0

    `define HEIGHT 600
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 2
    `define VSYNC_BPORCH 22
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 36Mhz
    // F_PLLOUT:      36  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0101111
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_800_600_60_Hz
    // VGA parameters: 800x600 @ 60Hz
    `define FPS 60
    `define WIDTH 800
    `define HSYNC_FPORCH 40
    `define HSYNC_PULSE 128
    `define HSYNC_BPORCH 88
    `define HSYNC_POLARITY_NEG 0

    `define HEIGHT 600
    `define VSYNC_FPORCH 1
    `define VSYNC_PULSE 4
    `define VSYNC_BPORCH 23
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 40Mhz
    // F_PLLOUT:   39.75  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0110100
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`elsif VGA_1024_768_43_Hz_INTERLACED
    // VGA parameters: 1024x768 @ 43Hz
    `define FPS 43
    `define WIDTH 1024
    `define HSYNC_FPORCH 8
    `define HSYNC_PULSE 176
    `define HSYNC_BPORCH 56
    `define HSYNC_POLARITY_NEG 0

    `define HEIGHT 768
    `define VSYNC_FPORCH 0
    `define VSYNC_PULSE 8
    `define VSYNC_BPORCH 41
    `define VSYNC_POLARITY_NEG 0

    // $icepll -i 12MHz -o 44.9Mhz
    // F_PLLOUT:      45  MHz (achieved)
    `define PLL_CLK_DIVR 4'b0000
    `define PLL_CLK_DIVF 7'b0111011
    `define PLL_CLK_DIVQ 3'b100
    `define PLL_CLK_FILTER_RANGE 3'b001
    `define PLL_CLK_RESETB 1'b1
    `define PLL_CLK_BYPASS 1'b0
`endif

`endif
