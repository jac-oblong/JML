/*
 * VGA specifications used in various modules
 */

localparam HRESOLUTION = 640;
localparam HFRONTPORCH = 16;
localparam HSYNCPULSE = 96;
localparam HBACKPORCH = 48;
localparam HTOTAL = HRESOLUTION + HFRONTPORCH + HSYNCPULSE + HBACKPORCH;
localparam HCOUNT_BITSREQ = $clog2(HTOTAL) - 1;

localparam VRESOLUTION = 480;
localparam VFRONTPORCH = 10;
localparam VSYNCPULSE = 2;
localparam VBACKPORCH = 33;
localparam VTOTAL = VRESOLUTION + VFRONTPORCH + VSYNCPULSE + VBACKPORCH;
localparam VCOUNT_BITSREQ = $clog2(VTOTAL) - 1;

localparam HSYNC_BEGIN = HRESOLUTION + HFRONTPORCH;
localparam HSYNC_END = HSYNC_BEGIN + HSYNCPULSE;
localparam VSYNC_BEGIN = VRESOLUTION + VFRONTPORCH;
localparam VSYNC_END = VSYNC_BEGIN + VSYNCPULSE;

localparam HTILES = HRESOLUTION / 8;
localparam VTILES = VRESOLUTION / 8;

localparam BUFFER_SIZE = 39;  // 39:0 for a total of 40 bits
localparam BUFFER_BITS = $clog2(BUFFER_SIZE) - 1;
