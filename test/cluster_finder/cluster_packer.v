//----------------------------------------------------------------------------------------------------------------------
// cluster.packer.v
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns / 100 ps
//----------------------------------------------------------------------------------------------------------------------
// clock 0: generate a cluster size count for each pad; generate cluster primary flags (vpfs)
// clock 1: vpfs and counts are routed through logic, and latched locally in the cluster_truncator and priority768 modules
//
//           cluster_truncator           |  priority encoder
//----------------------------------------------------------------------------------------------------------------------
// clock 2:  (n-1) truncated clusters
// clock 3:  (n-2) truncated clusters    ;  latch 1st cluster result
// clock 4:  (n-3) truncated clusters    ;  latch 2nd cluster result
// clock 7:  (n-4) truncated clusters    ;  latch 3rd cluster result
// clock 8:  (n-5) truncated clusters    ;  latch 4th cluster result
// clock 9:  (n-6) truncated clusters    ;  latch 5th cluster result
// clock 10: (n-7) truncated clusters    ;  latch 6th cluster result
// clock 11:                             ;  latch 7th cluster result
// clock 12: merge16 result stage 1
// clock 13: merge16 result stage 2
// clock 14: merge16 result stage 3 returns addresses/counts of first 8 clusters
//----------------------------------------------------------------------------------------------------------------------

//synthesis attribute ALLCLOCKNETS of cluster_packer is "240MHz"

module cluster_packer #(
  parameter SPLIT_CLUSTERS = 1
) (

  input             clock5x,
  input             clock4x,
  input             clock1x,
  input             reset_i,
  output reg [10:0] cluster_count,
  input      [3:0]  deadtime_i,

  input             trig_stop_i,

  input  [MXSBITS-1:0] vfat0,
  input  [MXSBITS-1:0] vfat1,
  input  [MXSBITS-1:0] vfat2,
  input  [MXSBITS-1:0] vfat3,
  input  [MXSBITS-1:0] vfat4,
  input  [MXSBITS-1:0] vfat5,
  input  [MXSBITS-1:0] vfat6,
  input  [MXSBITS-1:0] vfat7,
  input  [MXSBITS-1:0] vfat8,
  input  [MXSBITS-1:0] vfat9,
  input  [MXSBITS-1:0] vfat10,
  input  [MXSBITS-1:0] vfat11,
  input  [MXSBITS-1:0] vfat12,
  input  [MXSBITS-1:0] vfat13,
  input  [MXSBITS-1:0] vfat14,
  input  [MXSBITS-1:0] vfat15,
  input  [MXSBITS-1:0] vfat16,
  input  [MXSBITS-1:0] vfat17,
  input  [MXSBITS-1:0] vfat18,
  input  [MXSBITS-1:0] vfat19,
  input  [MXSBITS-1:0] vfat20,
  input  [MXSBITS-1:0] vfat21,
  input  [MXSBITS-1:0] vfat22,
  input  [MXSBITS-1:0] vfat23,

  output [MXCLSTBITS-1:0] cluster0,
  output [MXCLSTBITS-1:0] cluster1,
  output [MXCLSTBITS-1:0] cluster2,
  output [MXCLSTBITS-1:0] cluster3,
  output [MXCLSTBITS-1:0] cluster4,
  output [MXCLSTBITS-1:0] cluster5,
  output [MXCLSTBITS-1:0] cluster6,
  output [MXCLSTBITS-1:0] cluster7,

  output overflow
);

  //----------------------------------------------------------------------------------------------------------------------
  // Constants
  //----------------------------------------------------------------------------------------------------------------------

`include "constants.v"

  initial $display ("Compiling cluster packer:");
  initial $display ("    MXSBITS    = %d", MXSBITS);
  initial $display ("    MXKEYS     = %d", MXKEYS);
  initial $display ("    MXVFATS    = %d", MXVFATS);
  initial $display ("    MXROWS     = %d", MXROWS);
  initial $display ("    MXPADS     = %d", MXPADS);
  initial $display ("    MXCNTBITS  = %d", MXCNTBITS);
  initial $display ("    MXADRBITS  = %d", MXADRBITS);
  initial $display ("    MXCLSTBITS = %d", MXCLSTBITS);
  initial $display ("    MXCLUSTERS = %d", MXCLUSTERS);


  //----------------------------------------------------------------------------------------------------------------------
  // State machine power-up reset + global reset
  //----------------------------------------------------------------------------------------------------------------------

  // Reset -- keeps outputs off during reset time

  reg ready, reset;
  always @(posedge clock1x) begin
    ready <= ~reset;
    reset <= reset_i;
  end

  wire cluster_clock;
  assign cluster_clock = clock4x;

  //----------------------------------------------------------------------------------------------------------------------
  // clock 0: fire oneshots to prevent stuck bits and shorten the monostables
  //----------------------------------------------------------------------------------------------------------------------

  wire [MXSBITS-1:0] vfat_s0 [MXVFATS-1:0];
  wire [MXSBITS-1:0] vfat_os [MXVFATS-1:0];
  reg  [MXSBITS-1:0] vfat_s1 [MXVFATS-1:0];

  assign vfat_s0[0]  = vfat0;
  assign vfat_s0[1]  = vfat1;
  assign vfat_s0[2]  = vfat2;
  assign vfat_s0[3]  = vfat3;
  assign vfat_s0[4]  = vfat4;
  assign vfat_s0[5]  = vfat5;
  assign vfat_s0[6]  = vfat6;
  assign vfat_s0[7]  = vfat7;
  assign vfat_s0[8]  = vfat8;
  assign vfat_s0[9]  = vfat9;
  assign vfat_s0[10] = vfat10;
  assign vfat_s0[11] = vfat11;
  assign vfat_s0[12] = vfat12;
  assign vfat_s0[13] = vfat13;
  assign vfat_s0[14] = vfat14;
  assign vfat_s0[15] = vfat15;
  assign vfat_s0[16] = vfat16;
  assign vfat_s0[17] = vfat17;
  assign vfat_s0[18] = vfat18;
  assign vfat_s0[19] = vfat19;
  assign vfat_s0[20] = vfat20;
  assign vfat_s0[21] = vfat21;
  assign vfat_s0[22] = vfat22;
  assign vfat_s0[23] = vfat23;

  reg [3:0] deadtime;
  always @(posedge clock1x) begin
    deadtime <= deadtime_i;
  end

  wire clock_lac, latch_pulse_4x, latch_pulse_5x;
  reg latch_pulse_s1;
  lac lac      (
    .clock     ( clock1x),
    .clock4x   ( clock4x),
    .clock5x   ( clock5x),
    .clock_lac ( clock_lac),
    .strobe4x  ( latch_pulse_4x),
    .strobe5x  ( latch_pulse_5x)
  );

  always @(posedge cluster_clock) begin
    latch_pulse_s1 <= latch_pulse_4x;
  end

  genvar os_vfat;
  genvar os_sbit;
  generate
    for (os_vfat=0; os_vfat<MXVFATS; os_vfat=os_vfat+1'b1) begin  : os_vfatloop
      for (os_sbit=0; os_sbit<MXSBITS; os_sbit=os_sbit+1'b1) begin  : os_sbitloop

        x_oneshot sbit_oneshot (
          .d          (vfat_s0[os_vfat][os_sbit]),
          .q          (vfat_os[os_vfat][os_sbit]),
          .deadtime_i (deadtime),
          .clock      (cluster_clock),
          .slowclk    (clock1x)
        );

        always @(*)
          vfat_s1[os_vfat][os_sbit] <= vfat_os[os_vfat][os_sbit];

      end
    end
  endgenerate

  //----------------------------------------------------------------------------------------------------------------------
  // clock 1: Count cluster multiplicity for each pad
  //----------------------------------------------------------------------------------------------------------------------

  // remap vfats into partitions
  //--------------------------------------------------------------------------------

  reg [MXKEYS-1:0] partition [MXROWS-1:0];

  always @(*) begin
    partition[0] <= {vfat_s1[23], vfat_s1[15],  vfat_s1[7]};
    partition[1] <= {vfat_s1[22], vfat_s1[14],  vfat_s1[6]};
    partition[2] <= {vfat_s1[21], vfat_s1[13],  vfat_s1[5]};
    partition[3] <= {vfat_s1[20], vfat_s1[12],  vfat_s1[4]};
    partition[4] <= {vfat_s1[19], vfat_s1[11],  vfat_s1[3]};
    partition[5] <= {vfat_s1[18], vfat_s1[10],  vfat_s1[2]};
    partition[6] <= {vfat_s1[17], vfat_s1[9 ],  vfat_s1[1]};
    partition[7] <= {vfat_s1[16], vfat_s1[8 ],  vfat_s1[0]};
  end

  wire  [MXPADS-1:0] sbits_s0;

  genvar ikey, irow, ibit;
  generate
    for (irow=0; irow<MXROWS; irow=irow+1) begin: cluster_vpf_rowloop
      for (ikey=0; ikey<MXKEYS; ikey=ikey+1) begin: cluster_vpf_keyloop
        assign sbits_s0 [(MXKEYS*irow)+ikey] = partition[irow][ikey];
      end // row loop
    end // key_loop
  endgenerate

  // count cluster size and assign valid pattern flags
  //--------------------------------------------------------------------------------

	wire [MXPADS  -1        :0] vpfs;
  wire [MXPADS*MXCNTBITS-1:0] cnts;


	find_cluster_primaries #(
		.MXPADS         (MXPADS),
		.MXROWS         (MXROWS),
		.MXKEYS         (MXKEYS),
		.SPLIT_CLUSTERS (SPLIT_CLUSTERS) // 1=long clusters will be split in two (0=the tails are dropped)
	) find_cluster_primaries (
		.clock (cluster_clock),
		.sbits (sbits_s0),
		.vpfs  (vpfs),
		.cnts  (cnts)
	);

  // optional duplicate of vpfs for timing
  (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
  reg  [MXPADS  -1:0] vpfs_reg=0;
  (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
  reg  [MXPADS*MXCNTBITS-1:0] cnts_reg;

  always @(posedge cluster_clock) begin
    vpfs_reg <= vpfs;
    cnts_reg <= cnts;
  end

  // We count the number of cluster primaries. If it is greater than 8,
  // generate an overflow flag. This can be used to change the fiber's frame
  // separator to flag this to the receiving devices

  wire [10:0] cluster_count_s0;

  wire overflow_out;

  count_clusters u_count_clusters (
  .clock4x    (cluster_clock),
  .vpfs_i     (vpfs_reg),
  .cnt_o      (cluster_count_s0),
  .overflow_o (overflow_out)
  );

  always @(posedge clock1x) begin
    if (reset)
      cluster_count <= 8'd0;
    else
      cluster_count <= cluster_count_s0;
  end

  // FIXME: need to align overflow and cluster count to data

  // the output of the overflow flag should be delayed to lineup with the outputs from the priority encoding modules

  wire overflow_dly;

  parameter [3:0] OVERFLOW_DELAY = 7;
  SRL16E u_overflow_delay (
    .CLK (cluster_clock),
    .CE  (1'b1),
    .D   (overflow_out),
    .Q   (overflow_dly),
    .A0  (OVERFLOW_DELAY[0]),
    .A1 ( OVERFLOW_DELAY[1]),
    .A2 ( OVERFLOW_DELAY[2]),
    .A3 ( OVERFLOW_DELAY[3])
  );

  reg overflow_ff = 0;
  always @(posedge cluster_clock)
    overflow_ff <= (reset) ? 1'b0 : overflow_dly;
  assign overflow = overflow_ff;

  //----------------------------------------------------------------------------------------------------------------------
  // clock 3-12: priority encoding
  //----------------------------------------------------------------------------------------------------------------------

  wire [MXADRBITS-1:0] adr_encoder [MXCLUSTERS-1:0];
  wire [MXCNTBITS-1:0] cnt_encoder [MXCLUSTERS-1:0];

  cluster_finder u_first8 (
   .clock (cluster_clock),

   .vpfs_in (vpfs),
   .cnts_in (cnts),

   .latch_pulse(latch_pulse_s1),
   .latch_out(),

   .adr0  (adr_encoder [0]),
   .adr1  (adr_encoder [1]),
   .adr2  (adr_encoder [2]),
   .adr3  (adr_encoder [3]),
   .adr4  (adr_encoder [4]),
   .adr5  (adr_encoder [5]),
   .adr6  (adr_encoder [6]),
   .adr7  (adr_encoder [7]),

   .cnt0  (cnt_encoder [0]),
   .cnt1  (cnt_encoder [1]),
   .cnt2  (cnt_encoder [2]),
   .cnt3  (cnt_encoder [3]),
   .cnt4  (cnt_encoder [4]),
   .cnt5  (cnt_encoder [5]),
   .cnt6  (cnt_encoder [6]),
   .cnt7  (cnt_encoder [7]),

   .vpf0 (),
   .vpf1 (),
   .vpf2 (),
   .vpf3 (),
   .vpf4 (),
   .vpf5 (),
   .vpf6 (),
   .vpf7 ()

 );

  //----------------------------------------------------------------------------------------------------------------------
  // clock 13: build data packet
  //----------------------------------------------------------------------------------------------------------------------

  reg trig_stop;
  always @(posedge clock1x)
  trig_stop <= trig_stop_i;

  reg [MXCLSTBITS-1:0] cluster [7:0];

  genvar icluster;

  //--------------------------------------------------------------------------------------------------------------------
  // Initial values
  //--------------------------------------------------------------------------------------------------------------------

  generate
  for (icluster=0; icluster<8; icluster=icluster+1'b1) begin: clusterloop_init

  initial $display ("Initializing cluster_loop %d of %d", icluster, 7);

  initial cluster[icluster] = {3'd0,11'h7FE};
  end
  endgenerate

  localparam mxclst = 8;           // Number of clusters per bx

  generate
  for (icluster=0; icluster<mxclst; icluster=icluster+1'b1) begin: clusterloop

  initial $display ("Assigning cluster_loop %d of %d", icluster, MXCLUSTERS-1);
  //  14 bit hit format encoding
  //   hit[10:0]  = pad
  //   hit[13:11] = n adjacent pads hit  up to 7

  always @(posedge cluster_clock) begin
  cluster[icluster] <= reset     ? {3'd0, 11'h7FE} :
  trig_stop ? {3'd0, 11'h7FD} :
  {cnt_encoder[icluster], adr_encoder[icluster]};
  end

  end
  endgenerate

  assign cluster0 = cluster[0];
  assign cluster1 = cluster[1];
  assign cluster2 = cluster[2];
  assign cluster3 = cluster[3];
  assign cluster4 = cluster[4];
  assign cluster5 = cluster[5];
  assign cluster6 = cluster[6];
  assign cluster7 = cluster[7];

  //----------------------------------------------------------------------------------------------------------------------
  endmodule
  //----------------------------------------------------------------------------------------------------------------------
