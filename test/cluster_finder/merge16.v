module merge16 (
  input clock4x,

  input  mux_pulse_in,
  output mux_pulse_out,

  input [MXADRBITS-1:0] adr_in0,
  input [MXADRBITS-1:0] adr_in1,
  input [MXADRBITS-1:0] adr_in2,
  input [MXADRBITS-1:0] adr_in3,
  input [MXADRBITS-1:0] adr_in4,
  input [MXADRBITS-1:0] adr_in5,
  input [MXADRBITS-1:0] adr_in6,
  input [MXADRBITS-1:0] adr_in7,
  input [MXADRBITS-1:0] adr_in8,
  input [MXADRBITS-1:0] adr_in9,
  input [MXADRBITS-1:0] adr_in10,
  input [MXADRBITS-1:0] adr_in11,
  input [MXADRBITS-1:0] adr_in12,
  input [MXADRBITS-1:0] adr_in13,
  input [MXADRBITS-1:0] adr_in14,
  input [MXADRBITS-1:0] adr_in15,

  input [MXCNTBITS-1:0] cnt_in0,
  input [MXCNTBITS-1:0] cnt_in1,
  input [MXCNTBITS-1:0] cnt_in2,
  input [MXCNTBITS-1:0] cnt_in3,
  input [MXCNTBITS-1:0] cnt_in4,
  input [MXCNTBITS-1:0] cnt_in5,
  input [MXCNTBITS-1:0] cnt_in6,
  input [MXCNTBITS-1:0] cnt_in7,
  input [MXCNTBITS-1:0] cnt_in8,
  input [MXCNTBITS-1:0] cnt_in9,
  input [MXCNTBITS-1:0] cnt_in10,
  input [MXCNTBITS-1:0] cnt_in11,
  input [MXCNTBITS-1:0] cnt_in12,
  input [MXCNTBITS-1:0] cnt_in13,
  input [MXCNTBITS-1:0] cnt_in14,
  input [MXCNTBITS-1:0] cnt_in15,

  output [MXADRBITS-1:0] adr0_o,
  output [MXADRBITS-1:0] adr1_o,
  output [MXADRBITS-1:0] adr2_o,
  output [MXADRBITS-1:0] adr3_o,
  output [MXADRBITS-1:0] adr4_o,
  output [MXADRBITS-1:0] adr5_o,
  output [MXADRBITS-1:0] adr6_o,
  output [MXADRBITS-1:0] adr7_o,

  output [MXCNTBITS-1:0] cnt0_o,
  output [MXCNTBITS-1:0] cnt1_o,
  output [MXCNTBITS-1:0] cnt2_o,
  output [MXCNTBITS-1:0] cnt3_o,
  output [MXCNTBITS-1:0] cnt4_o,
  output [MXCNTBITS-1:0] cnt5_o,
  output [MXCNTBITS-1:0] cnt6_o,
  output [MXCNTBITS-1:0] cnt7_o
);

parameter MXADRBITS=11;
parameter MXCNTBITS=3;

//`define input_latch 1
 `define s0_latch 1
//   `define s1_latch 1
 `define s2_latch 1
 `define s3_latch 1


//----------------------------------------------------------------------------------------------------------------------
// vectorize inputs
//----------------------------------------------------------------------------------------------------------------------

  reg [MXADRBITS-1:0] adr [15:0];   reg [MXCNTBITS-1:0] cnt [15:0];
  reg mux_pulse;

  `ifdef input_latch
    always @(posedge clock4x) begin
  `else
    always @(*) begin
  `endif

    adr[0]  <=  adr_in0;              cnt[0]  <= cnt_in0;
    adr[1]  <=  adr_in1;              cnt[1]  <= cnt_in1;
    adr[2]  <=  adr_in2;              cnt[2]  <= cnt_in2;
    adr[3]  <=  adr_in3;              cnt[3]  <= cnt_in3;
    adr[4]  <=  adr_in4;              cnt[4]  <= cnt_in4;
    adr[5]  <=  adr_in5;              cnt[5]  <= cnt_in5;
    adr[6]  <=  adr_in6;              cnt[6]  <= cnt_in6;
    adr[7]  <=  adr_in7;              cnt[7]  <= cnt_in7;
    adr[8]  <=  adr_in8;              cnt[8]  <= cnt_in8;
    adr[9]  <=  adr_in9;              cnt[9]  <= cnt_in9;
    adr[10] <=  adr_in10;             cnt[10] <= cnt_in10;
    adr[11] <=  adr_in11;             cnt[11] <= cnt_in11;
    adr[12] <=  adr_in12;             cnt[12] <= cnt_in12;
    adr[13] <=  adr_in13;             cnt[13] <= cnt_in13;
    adr[14] <=  adr_in14;             cnt[14] <= cnt_in14;
    adr[15] <=  adr_in15;             cnt[15] <= cnt_in15;

    mux_pulse <= mux_pulse_in;

  end

  // stage 0: sort eights (0,8), (1,9), (2,10), (3,11), (4,12), (5,13), (6,14), (7,15)
  //------------------------------------------------------------------------------------------------------------------

  reg  [MXCNTBITS-1:0] cnt_s0 [15:0];
  reg  [MXADRBITS-1:0] adr_s0 [15:0];
  reg                  mux_pulse_s0;

  `ifdef s0_latch
    always @(posedge clock4x) begin
  `else
    always @(*) begin
  `endif

     {{adr_s0[0], cnt_s0[0]},  {adr_s0[8],  cnt_s0[8]}}   <=  adr[0] < adr[8]  ? {{adr[0], cnt[0]}, {adr[8],  cnt[ 8]}} : {{adr[8],  cnt[ 8]}, {adr[0], cnt[0]}};
     {{adr_s0[1], cnt_s0[1]},  {adr_s0[9],  cnt_s0[9]}}   <=  adr[1] < adr[9]  ? {{adr[1], cnt[1]}, {adr[9],  cnt[ 9]}} : {{adr[9],  cnt[ 9]}, {adr[1], cnt[1]}};
     {{adr_s0[2], cnt_s0[2]},  {adr_s0[10], cnt_s0[10]}}  <=  adr[2] < adr[10] ? {{adr[2], cnt[2]}, {adr[10], cnt[10]}} : {{adr[10], cnt[10]}, {adr[2], cnt[2]}};
     {{adr_s0[3], cnt_s0[3]},  {adr_s0[11], cnt_s0[11]}}  <=  adr[3] < adr[11] ? {{adr[3], cnt[3]}, {adr[11], cnt[11]}} : {{adr[11], cnt[11]}, {adr[3], cnt[3]}};
     {{adr_s0[4], cnt_s0[4]},  {adr_s0[12], cnt_s0[12]}}  <=  adr[4] < adr[12] ? {{adr[4], cnt[4]}, {adr[12], cnt[12]}} : {{adr[12], cnt[12]}, {adr[4], cnt[4]}};
     {{adr_s0[5], cnt_s0[5]},  {adr_s0[13], cnt_s0[13]}}  <=  adr[5] < adr[13] ? {{adr[5], cnt[5]}, {adr[13], cnt[13]}} : {{adr[13], cnt[13]}, {adr[5], cnt[5]}};
     {{adr_s0[6], cnt_s0[6]},  {adr_s0[14], cnt_s0[14]}}  <=  adr[6] < adr[14] ? {{adr[6], cnt[6]}, {adr[14], cnt[14]}} : {{adr[14], cnt[14]}, {adr[6], cnt[6]}};
     {{adr_s0[7], cnt_s0[7]},  {adr_s0[15], cnt_s0[15]}}  <=  adr[7] < adr[15] ? {{adr[7], cnt[7]}, {adr[15], cnt[15]}} : {{adr[15], cnt[15]}, {adr[7], cnt[7]}};

       mux_pulse_s0 <= mux_pulse;

    end

  // stage 1: sort fours (4,8), (5,9), (6,10), (7,11)
  //------------------------------------------------------------------------------------------------------------------

  reg [MXCNTBITS-1:0] cnt_s1 [15:0];
  reg [MXADRBITS-1:0] adr_s1 [15:0];

  reg       mux_pulse_s1;


  `ifdef s1_latch
    always @(posedge clock4x) begin
  `else
    always @(*) begin
  `endif

      {adr_s1[0],   cnt_s1[0]}  <= {adr_s0[0],  cnt_s0[0]};
      {adr_s1[1],   cnt_s1[1]}  <= {adr_s0[1],  cnt_s0[1]};
      {adr_s1[2],   cnt_s1[2]}  <= {adr_s0[2],  cnt_s0[2]};
      {adr_s1[3],   cnt_s1[3]}  <= {adr_s0[3],  cnt_s0[3]};

      {{adr_s1[4],  cnt_s1[4]},  {adr_s1[8],   cnt_s1[8]}}  <= adr_s0[4]  < adr_s0[8]  ? {{adr_s0[4], cnt_s0[4]}, {adr_s0[8],  cnt_s0[8]}}  : {{adr_s0[8],   cnt_s0[8]},  {adr_s0[4], cnt_s0[4]}};
      {{adr_s1[5],  cnt_s1[5]},  {adr_s1[9],   cnt_s1[9]}}  <= adr_s0[5]  < adr_s0[9]  ? {{adr_s0[5], cnt_s0[5]}, {adr_s0[9],  cnt_s0[9]}}  : {{adr_s0[9],   cnt_s0[9]},  {adr_s0[5], cnt_s0[5]}};
      {{adr_s1[6],  cnt_s1[6]},  {adr_s1[10],  cnt_s1[10]}} <= adr_s0[6]  < adr_s0[10] ? {{adr_s0[6], cnt_s0[6]}, {adr_s0[10], cnt_s0[10]}} : {{adr_s0[10],  cnt_s0[10]}, {adr_s0[6], cnt_s0[6]}};
      {{adr_s1[7],  cnt_s1[7]},  {adr_s1[11],  cnt_s1[11]}} <= adr_s0[7]  < adr_s0[11] ? {{adr_s0[7], cnt_s0[7]}, {adr_s0[11], cnt_s0[11]}} : {{adr_s0[11],  cnt_s0[11]}, {adr_s0[7], cnt_s0[7]}};

      {adr_s1[12],  cnt_s1[12]} <= {adr_s0[12], cnt_s0[12]};
      {adr_s1[13],  cnt_s1[13]} <= {adr_s0[13], cnt_s0[13]};
      {adr_s1[14],  cnt_s1[14]} <= {adr_s0[14], cnt_s0[14]};
      {adr_s1[15],  cnt_s1[15]} <= {adr_s0[15], cnt_s0[15]};

      mux_pulse_s1 <= mux_pulse_s0;

  end

  // stage 2: sort twos (2,4), (3,5), (6,8), (7,9)
  //------------------------------------------------------------------------------------------------------------------

  reg [MXCNTBITS-1:0] cnt_s2 [15:0];
  reg [MXADRBITS-1:0] adr_s2 [15:0];

  reg       mux_pulse_s2;


  `ifdef s2_latch
    always @(posedge clock4x) begin
  `else
    always @(*) begin
  `endif

      {adr_s2[0],  cnt_s2[0]} <= {adr_s1[0], cnt_s1[0]};
      {adr_s2[1],  cnt_s2[1]} <= {adr_s1[1], cnt_s1[1]};

      {{adr_s2[2],  cnt_s2[2]},  {adr_s2[4],  cnt_s2[4]}}  <= adr_s1[2]  < adr_s1[4]  ? {{adr_s1[2],  cnt_s1[2]},  {adr_s1[4],  cnt_s1[4]}}  : {{adr_s1[4],  cnt_s1[4]},  {adr_s1[2],  cnt_s1[2]}};
      {{adr_s2[3],  cnt_s2[3]},  {adr_s2[5],  cnt_s2[5]}}  <= adr_s1[3]  < adr_s1[5]  ? {{adr_s1[3],  cnt_s1[3]},  {adr_s1[5],  cnt_s1[5]}}  : {{adr_s1[5],  cnt_s1[5]},  {adr_s1[3],  cnt_s1[3]}};
      {{adr_s2[6],  cnt_s2[6]},  {adr_s2[8],  cnt_s2[8]}}  <= adr_s1[6]  < adr_s1[8]  ? {{adr_s1[6],  cnt_s1[6]},  {adr_s1[8],  cnt_s1[8]}}  : {{adr_s1[8],  cnt_s1[8]},  {adr_s1[6],  cnt_s1[6]}};
      {{adr_s2[7],  cnt_s2[7]},  {adr_s2[9],  cnt_s2[9]}}  <= adr_s1[7]  < adr_s1[9]  ? {{adr_s1[7],  cnt_s1[7]},  {adr_s1[9],  cnt_s1[9]}}  : {{adr_s1[9],  cnt_s1[9]},  {adr_s1[7],  cnt_s1[7]}};
      {{adr_s2[10], cnt_s2[10]}, {adr_s2[12], cnt_s2[12]}} <= adr_s1[10] < adr_s1[12] ? {{adr_s1[10], cnt_s1[10]}, {adr_s1[12], cnt_s1[12]}} : {{adr_s1[12], cnt_s1[12]}, {adr_s1[10], cnt_s1[10]}};
      {{adr_s2[11], cnt_s2[11]}, {adr_s2[13], cnt_s2[13]}} <= adr_s1[11] < adr_s1[13] ? {{adr_s1[11], cnt_s1[11]}, {adr_s1[13], cnt_s1[13]}} : {{adr_s1[13], cnt_s1[13]}, {adr_s1[11], cnt_s1[11]}};

      {adr_s2[14],  cnt_s2[14]} <= {adr_s1[14], cnt_s1[14]};
      {adr_s2[15],  cnt_s2[15]} <= {adr_s1[15], cnt_s1[15]};

      mux_pulse_s2 <= mux_pulse_s1;
  end

  // stage 3: swap odd pairs (1,2), (3,4), (5,6), (7,8), (9,10), (11,12), (13,14)
  //------------------------------------------------------------------------------------------------------------------

  reg [MXCNTBITS-1:0] cnt_s3 [15:0];
  reg [MXADRBITS-1:0] adr_s3 [15:0];

  reg  mux_pulse_s3;


  `ifdef s3_latch
    always @(posedge clock4x) begin
  `else
    always @(*) begin
  `endif

      {adr_s3[0],  cnt_s3[0]} = {adr_s2[0],  cnt_s2[0]};

     {{adr_s3[1],  cnt_s3[1]},  {adr_s3[2],  cnt_s3[2]}}  = adr_s2[1]  < adr_s2[2]  ? {{adr_s2[1],  cnt_s2[1]},  {adr_s2[2],  cnt_s2[2]}}  : {{adr_s2[2],  cnt_s2[2]},  {adr_s2[1],  cnt_s2[1]}};
     {{adr_s3[3],  cnt_s3[3]},  {adr_s3[4],  cnt_s3[4]}}  = adr_s2[3]  < adr_s2[4]  ? {{adr_s2[3],  cnt_s2[3]},  {adr_s2[4],  cnt_s2[4]}}  : {{adr_s2[4],  cnt_s2[4]},  {adr_s2[3],  cnt_s2[3]}};
     {{adr_s3[5],  cnt_s3[5]},  {adr_s3[6],  cnt_s3[6]}}  = adr_s2[5]  < adr_s2[6]  ? {{adr_s2[5],  cnt_s2[5]},  {adr_s2[6],  cnt_s2[6]}}  : {{adr_s2[6],  cnt_s2[6]},  {adr_s2[5],  cnt_s2[5]}};
     {{adr_s3[7],  cnt_s3[7]},  {adr_s3[8],  cnt_s3[8]}}  = adr_s2[7]  < adr_s2[8]  ? {{adr_s2[7],  cnt_s2[7]},  {adr_s2[8],  cnt_s2[8]}}  : {{adr_s2[8],  cnt_s2[8]},  {adr_s2[7],  cnt_s2[7]}};
     {{adr_s3[9],  cnt_s3[9]},  {adr_s3[10], cnt_s3[10]}} = adr_s2[9]  < adr_s2[10] ? {{adr_s2[9],  cnt_s2[9]},  {adr_s2[10], cnt_s2[10]}} : {{adr_s2[10], cnt_s2[10]}, {adr_s2[9],  cnt_s2[9]}};
     {{adr_s3[11], cnt_s3[11]}, {adr_s3[12], cnt_s3[12]}} = adr_s2[11] < adr_s2[12] ? {{adr_s2[11], cnt_s2[11]}, {adr_s2[12], cnt_s2[12]}} : {{adr_s2[12], cnt_s2[12]}, {adr_s2[11], cnt_s2[11]}};
     {{adr_s3[13], cnt_s3[13]}, {adr_s3[14], cnt_s3[14]}} = adr_s2[13] < adr_s2[14] ? {{adr_s2[13], cnt_s2[13]}, {adr_s2[14], cnt_s2[14]}} : {{adr_s2[14], cnt_s2[14]}, {adr_s2[13], cnt_s2[13]}};

     {adr_s3[15],  cnt_s3[15]} = {adr_s2[15],  cnt_s2[15]};

      mux_pulse_s3 = mux_pulse_s2;

    end

//----------------------------------------------------------------------------------------------------------------------
// Latch Results for Output
//----------------------------------------------------------------------------------------------------------------------

      assign {adr0_o,cnt0_o} = {adr_s3[0],cnt_s3[0]};
      assign {adr1_o,cnt1_o} = {adr_s3[1],cnt_s3[1]};
      assign {adr2_o,cnt2_o} = {adr_s3[2],cnt_s3[2]};
      assign {adr3_o,cnt3_o} = {adr_s3[3],cnt_s3[3]};
      assign {adr4_o,cnt4_o} = {adr_s3[4],cnt_s3[4]};
      assign {adr5_o,cnt5_o} = {adr_s3[5],cnt_s3[5]};
      assign {adr6_o,cnt6_o} = {adr_s3[6],cnt_s3[6]};
      assign {adr7_o,cnt7_o} = {adr_s3[7],cnt_s3[7]};

      assign mux_pulse_out = mux_pulse_s3;

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
