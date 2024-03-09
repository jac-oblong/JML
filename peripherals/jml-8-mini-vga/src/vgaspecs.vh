/*
 * VGA specifications used in various modules
 */

localparam HBACKPORCH = 48;
localparam HRESOLUTION = 640;
localparam HFRONTPORCH = 16;
localparam HSYNCPULSE = 96;
localparam HTOTAL = HBACKPORCH + HRESOLUTION + HFRONTPORCH + HSYNCPULSE;
localparam HCOUNT_BITSREQ = $clog2(HTOTAL) - 1;

localparam VBACKPORCH = 33;
localparam VRESOLUTION = 480;
localparam VFRONTPORCH = 10;
localparam VSYNCPULSE = 2;
localparam VTOTAL = VBACKPORCH + VRESOLUTION + VFRONTPORCH + VSYNCPULSE;
localparam VCOUNT_BITSREQ = $clog2(VTOTAL) - 1;

localparam HSYNC_BEGIN = HBACKPORCH + HRESOLUTION + HFRONTPORCH;
localparam HSYNC_END = HSYNC_BEGIN + HSYNCPULSE;
localparam VSYNC_BEGIN = VBACKPORCH + VRESOLUTION + VFRONTPORCH;
localparam VSYNC_END = VSYNC_BEGIN + VSYNCPULSE;

localparam HVISIBLE_BEGIN = HBACKPORCH;
localparam HVISIBLE_END = HVISIBLE_BEGIN + HRESOLUTION;
localparam VVISIBLE_BEGIN = VBACKPORCH;
localparam VVISIBLE_END = VVISIBLE_BEGIN + VRESOLUTION;

localparam HTILES_ = HRESOLUTION / 8;  // avoids warning based on data width
localparam VTILES = VRESOLUTION / 8;
localparam HTILES_BITSREQ = $clog2(HTILES_ - 1) - 1;
localparam VTILES_BITSREQ = $clog2(VTILES - 1) - 1;
localparam HTILES = HTILES_[HTILES_BITSREQ:0];

localparam DUALPORT_SIZE = 127;
localparam DUALPORT_BITSREQ = $clog2(DUALPORT_SIZE) - 1;
