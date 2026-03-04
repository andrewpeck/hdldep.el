//`define debug_priority1536
`timescale 1ns / 100 ps

module priority768 (

  input clock,

  input latch_pulse,

  input  [2:0] pass_in,
  output reg [2:0] pass_out,

  input   [MXKEYS  -1:0] vpfs_in,
  input   [MXKEYS*3-1:0] cnts_in,

  output reg cluster_found,

  output reg  [10:0] adr,
  output reg   [2:0] cnt
);

  parameter MXLATCHES = 16;
  parameter MXKEYS    = 768;
  parameter MXKEYBITS = 10;

  (* MAX_FANOUT = 128 *)
  (* DONT_TOUCH = "TRUE" *)
  (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
  reg [MXLATCHES-1:0] latch_en=0;
  always @(posedge clock)
    latch_en <= {MXLATCHES{latch_pulse}};

//----------------------------------------------------------------------------------------------------------------------
// Input registers and delays
//----------------------------------------------------------------------------------------------------------------------

  reg   [MXKEYS-1:0] vpfs;
  reg   [2:0] cnts_latch [MXKEYS-1:0];
  reg   [2:0] cnts       [MXKEYS-1:0];

  genvar ipad;
  generate
  for (ipad=0; ipad<MXKEYS; ipad=ipad+1) begin: padloop
    always @(posedge clock) begin
      if (latch_en[ipad/(MXKEYS/MXLATCHES)])
        cnts_latch [ipad] <= cnts_in [ipad*3+2:ipad*3];
    end

    always @(posedge clock)
      cnts[ipad] <= cnts_latch[ipad];
  end
  endgenerate

  always @(posedge clock)
    vpfs <= vpfs_in;

  // Shadow copy of pass counter

  reg [2:0] pass;
  always @(posedge clock)
    pass <= pass_in;


//----------------------------------------------------------------------------------------------------------------------
// Parameters and Interconnects
//----------------------------------------------------------------------------------------------------------------------

  //`define s0_latch
  //`define s1_latch
  //`define s2_latch
  `define s3_latch
  //`define s4_latch
  //`define s5_latch
  //`define s6_latch
  //`define s7_latch
  //`define s8_latch
  `define output_latch


  reg [2:0] pass_s0;
  reg [2:0] pass_s1;
  reg [2:0] pass_s2;
  reg [2:0] pass_s3;
  reg [2:0] pass_s4;
  reg [2:0] pass_s5;
  reg [2:0] pass_s6;
  reg [2:0] pass_s7;
  reg [2:0] pass_s8;

  reg [ 383:0] vpf_s0;
  reg [ 191:0] vpf_s1;
  reg [  95:0] vpf_s2;
  reg [  47:0] vpf_s3;
  reg [  23:0] vpf_s4;
  reg [  11:0] vpf_s5;
  reg [   5:0] vpf_s6;
  reg [   2:0] vpf_s7;
  reg [   0:0] vpf_s8;

  reg [MXKEYBITS-10:0] key_s0 [383:0];
  reg [MXKEYBITS- 9:0] key_s1 [191:0];
  reg [MXKEYBITS- 8:0] key_s2 [ 95:0];
  reg [MXKEYBITS- 7:0] key_s3 [ 47:0];
  reg [MXKEYBITS- 6:0] key_s4 [ 23:0];
  reg [MXKEYBITS- 5:0] key_s5 [ 11:0];
  reg [MXKEYBITS- 4:0] key_s6 [  5:0];
  reg [MXKEYBITS- 3:0] key_s7 [  2:0];
  reg [MXKEYBITS- 1:0] key_s8 [  0:0];

  reg [2:0] cnt_s0 [383:0];
  reg [2:0] cnt_s1 [191:0];
  reg [2:0] cnt_s2 [ 95:0];
  reg [2:0] cnt_s3 [ 47:0];
  reg [2:0] cnt_s4 [ 23:0];
  reg [2:0] cnt_s5 [ 11:0];
  reg [2:0] cnt_s6 [  5:0];
  reg [2:0] cnt_s7 [  2:0];
  reg [2:0] cnt_s8 [  0:0];

  // Stage 0 : 384 of 768
  genvar ihit;
  generate
  for (ihit=0; ihit<MXKEYS/2; ihit=ihit+1) begin: s0
    `ifdef s0_latch
    always @(posedge clock)
    `else
    always @(*)
    `endif
    {vpf_s0[ihit], cnt_s0[ihit], key_s0[ihit]} <= (vpfs[ihit*2]) ? {vpfs[ihit*2], cnts[ihit*2], 1'b0} : {vpfs[ihit*2+1], cnts[ihit*2+1], 1'b1} ;
  end
  endgenerate

  `ifdef s0_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s0 = pass;

  // Stage 1: 192 of 384
  generate
  for (ihit=0; ihit<MXKEYS/4; ihit=ihit+1) begin: s1
  `ifdef s1_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s1[ihit], cnt_s1[ihit], key_s1[ihit]} = vpf_s0[ihit*2] ?  {vpf_s0[ihit*2  ], cnt_s0[ihit*2], {1'b0,key_s0[ihit*2  ]}} : {vpf_s0[ihit*2+1], cnt_s0[ihit*2+1], {1'b1,key_s0[ihit*2+1]}};
  end
  endgenerate

  `ifdef s1_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s1 = pass_s0;

  // Stage 2: 96 of 192
  generate
  for (ihit=0; ihit<MXKEYS/8; ihit=ihit+1) begin: s2
  `ifdef s2_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s2[ihit], cnt_s2[ihit], key_s2[ihit]} = vpf_s1[ihit*2] ?  {vpf_s1[ihit*2  ], cnt_s1[ihit*2], {1'b0,key_s1[ihit*2  ]}} : {vpf_s1[ihit*2+1], cnt_s1[ihit*2+1], {1'b1,key_s1[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s2_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s2 = pass_s1;

  // Stage 3: 48 of 96
  generate
  for (ihit=0; ihit<MXKEYS/16; ihit=ihit+1) begin: s3
  `ifdef s3_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s3[ihit], cnt_s3[ihit], key_s3[ihit]} <= vpf_s2[ihit*2] ?  {vpf_s2[ihit*2  ], cnt_s2[ihit*2], {1'b0,key_s2[ihit*2  ]}} : {vpf_s2[ihit*2+1], cnt_s2[ihit*2+1], {1'b1,key_s2[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s3_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s3 <= pass_s2;

  // Stage 4: 24 of 48
  generate
  for (ihit=0; ihit<MXKEYS/32; ihit=ihit+1) begin: s4
  `ifdef s4_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s4[ihit], cnt_s4[ihit], key_s4[ihit]} = vpf_s3[ihit*2] ?  {vpf_s3[ihit*2  ], cnt_s3[ihit*2], {1'b0,key_s3[ihit*2  ]}} : {vpf_s3[ihit*2+1], cnt_s3[ihit*2+1], {1'b1,key_s3[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s4_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s4 = pass_s3;

  // stage 5: 12 of 24
  generate
  for (ihit=0; ihit<MXKEYS/64; ihit=ihit+1) begin: s5
  `ifdef s5_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s5[ihit], cnt_s5[ihit], key_s5[ihit]} = vpf_s4[ihit*2] ?  {vpf_s4[ihit*2  ], cnt_s4[ihit*2], {1'b0,key_s4[ihit*2  ]}} : {vpf_s4[ihit*2+1], cnt_s4[ihit*2+1], {1'b1,key_s4[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s5_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s5 = pass_s4;

  // stage 6: 6 of 12
  generate
  for (ihit=0; ihit<MXKEYS/128; ihit=ihit+1) begin: s6
  `ifdef s6_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s6[ihit], cnt_s6[ihit], key_s6[ihit]} = vpf_s5[ihit*2] ?  {vpf_s5[ihit*2  ], cnt_s5[ihit*2], {1'b0,key_s5[ihit*2  ]}} : {vpf_s5[ihit*2+1], cnt_s5[ihit*2+1], {1'b1,key_s5[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s6_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s6 = pass_s5;

  // stage 7: 3 of 6
  generate
  for (ihit=0; ihit<MXKEYS/256; ihit=ihit+1) begin: s7
  `ifdef s7_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    {vpf_s7[ihit], cnt_s7[ihit], key_s7[ihit]} = vpf_s6[ihit*2] ?  {vpf_s6[ihit*2  ], cnt_s6[ihit*2], {1'b0,key_s6[ihit*2  ]}} : {vpf_s6[ihit*2+1], cnt_s6[ihit*2+1], {1'b1,key_s6[ihit*2+1]}} ;
  end
  endgenerate

  `ifdef s7_latch
  always @(posedge clock)
  `else
  always @(*)
  `endif
    pass_s7 = pass_s6;

  // Stage 6: 1 of 3 Parallel Encoder
  `ifdef s8_latch
  always @(posedge clock) begin
  `else
  always @(*) begin
  `endif

    if      (vpf_s7[0]) {vpf_s8[0], cnt_s8[0], key_s8[0]} = {vpf_s7[0], cnt_s7[0], {2'b00, key_s7[0]}};
    else if (vpf_s7[1]) {vpf_s8[0], cnt_s8[0], key_s8[0]} = {vpf_s7[1], cnt_s7[1], {2'b01, key_s7[1]}};
    else                {vpf_s8[0], cnt_s8[0], key_s8[0]} = {vpf_s7[2], cnt_s7[2], {2'b10, key_s7[2]}};

    pass_s8 <= pass_s7;

  end


  `ifdef output_latch
  always @(posedge clock) begin
  `else
  always @(*) begin
  `endif
    adr           <= {11{~vpf_s8[0]}} | key_s8[0];
    cluster_found <=                    vpf_s8[0];
    cnt           <= {3 { vpf_s8[0]}} & cnt_s8[0];
    pass_out      <= pass_s8;

  end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
