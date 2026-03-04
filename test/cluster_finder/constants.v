`define first8

localparam MXSBITS      = 64; // S-bits per vfat

localparam OH_LITE      = 0;         //
localparam MXKEYS       = 3*MXSBITS; // Vfats  per partition
localparam MXROWS       = 8;         // Eta partitions per chamber
localparam MXCLUSTERS   = 8;         // Number of clusters per bx

//--------------------------------------------------------------------------------------------------------------------
// Generic
//--------------------------------------------------------------------------------------------------------------------

localparam MXVFATS    = 24-12*OH_LITE;       // Number of VFATs
localparam MXPADS     = (MXKEYS*MXROWS);     // S-bits per chamber
localparam MXCNTBITS  = 3;                   // Number of count   bits per cluster
localparam MXADRBITS  = 11;                  // Number of address bits per cluster
localparam MXCLSTBITS = MXCNTBITS+MXADRBITS; // Number of total   bits per cluster
