//----------------------------------------------------------------------------------------------------------------------
// encoder_mux.v
//
// The cluster_packer is based around two priority encoding modules
// (first8of1536). One encoder handles the S-bits received at "even" bunch
// crossings, while the other handles S-bits received at the "odd" bunch
// crossing.
//
//----------------------------------------------------------------------------------------------------------------------

module encoder_mux (

  input clock_lac,
  input latch_pulse,
  output latch_out,

  input clock4x,
  input clock5x,

  input  [1536-1:0]    vpfs_in,

  input  [1536*3-1:0]  cnts_in,

  output [2:0] cnt0,
  output [2:0] cnt1,
  output [2:0] cnt2,
  output [2:0] cnt3,
  output [2:0] cnt4,
  output [2:0] cnt5,
  output [2:0] cnt6,
  output [2:0] cnt7,

  output [10:0] adr0,
  output [10:0] adr1,
  output [10:0] adr2,
  output [10:0] adr3,
  output [10:0] adr4,
  output [10:0] adr5,
  output [10:0] adr6,
  output [10:0] adr7
);

//----------------------------------------------------------------------------------------------------------------------
// latch_enable
//----------------------------------------------------------------------------------------------------------------------

  wire [10:0] encoder_adr0  [1:0];
  wire [10:0] encoder_adr1  [1:0];
  wire [10:0] encoder_adr2  [1:0];
  wire [10:0] encoder_adr3  [1:0];
  wire [10:0] encoder_adr4  [1:0];
  wire [10:0] encoder_adr5  [1:0];
  wire [10:0] encoder_adr6  [1:0];
  wire [10:0] encoder_adr7  [1:0];
  wire [10:0] encoder_adr8  [1:0];
  wire [10:0] encoder_adr9  [1:0];
  wire [10:0] encoder_adr10 [1:0];
  wire [10:0] encoder_adr11 [1:0];
  wire [10:0] encoder_adr12 [1:0];
  wire [10:0] encoder_adr13 [1:0];
  wire [10:0] encoder_adr14 [1:0];
  wire [10:0] encoder_adr15 [1:0];

  wire  [2:0] encoder_cnt0  [1:0];
  wire  [2:0] encoder_cnt1  [1:0];
  wire  [2:0] encoder_cnt2  [1:0];
  wire  [2:0] encoder_cnt3  [1:0];
  wire  [2:0] encoder_cnt4  [1:0];
  wire  [2:0] encoder_cnt5  [1:0];
  wire  [2:0] encoder_cnt6  [1:0];
  wire  [2:0] encoder_cnt7  [1:0];
  wire  [2:0] encoder_cnt8  [1:0];
  wire  [2:0] encoder_cnt9  [1:0];
  wire  [2:0] encoder_cnt10 [1:0];
  wire  [2:0] encoder_cnt11 [1:0];
  wire  [2:0] encoder_cnt12 [1:0];
  wire  [2:0] encoder_cnt13 [1:0];
  wire  [2:0] encoder_cnt14 [1:0];
  wire  [2:0] encoder_cnt15 [1:0];

  wire  [0:0] encoder_vpf0  [1:0];
  wire  [0:0] encoder_vpf1  [1:0];
  wire  [0:0] encoder_vpf2  [1:0];
  wire  [0:0] encoder_vpf3  [1:0];
  wire  [0:0] encoder_vpf4  [1:0];
  wire  [0:0] encoder_vpf5  [1:0];
  wire  [0:0] encoder_vpf6  [1:0];
  wire  [0:0] encoder_vpf7  [1:0];
  wire  [0:0] encoder_vpf8  [1:0];
  wire  [0:0] encoder_vpf9  [1:0];
  wire  [0:0] encoder_vpf10 [1:0];
  wire  [0:0] encoder_vpf11 [1:0];
  wire  [0:0] encoder_vpf12 [1:0];
  wire  [0:0] encoder_vpf13 [1:0];
  wire  [0:0] encoder_vpf14 [1:0];
  wire  [0:0] encoder_vpf15 [1:0];

  wire  [1:0] encoder_latch_out;

  reg [10:0] adr_muxed  [15:0];
  reg  [2:0] cnt_muxed  [15:0];
  reg  [0:0] vpf_muxed  [15:0];
  reg        encoder_latch_muxed;

  // multiplex cluster outputs from the two priority encoder modules


  // latch is coming every 25 ns, but want to slow it down to every 50 so just pass every other
  reg latch_allow = 1'b1;
  always @(posedge clock4x) begin
    if (latch_pulse) begin
      latch_allow <= ~latch_allow;
    end
  end


  // delay the second latch pulse by 25ns (SRL=2 delays by 3 plus a ff for fanout)

  wire latch_pulse_dly_srl;
  parameter [3:0] latch_dly = 4'd2;
  SRL16E u_latch_dly (.CLK(clock4x),.CE(1'b1),.D(latch_allow & latch_pulse),.A0(latch_dly[0]),.A1(latch_dly[1]),.A2(latch_dly[2]),.A3(latch_dly[3]),.Q(latch_pulse_dly_srl));

  reg latch_pulse_delayed = 0;
  always @(posedge clock4x) begin
    latch_pulse_delayed <= latch_pulse_dly_srl;
  end

  wire [1:0] latch_pulse_arr;

  assign latch_pulse_arr[0] =  (latch_allow & latch_pulse);
  assign latch_pulse_arr[1] =  latch_pulse_delayed;

  genvar iencoder;
  generate
  for (iencoder=0; iencoder<2; iencoder=iencoder+1) begin: encloop

    first16of1536 u_first16 (

        .clock4x(clock4x),
        .clock5x(clock5x),
        .vpfs_in (vpfs_in),
        .cnts_in (cnts_in),

        .latch_pulse (latch_pulse_arr [iencoder]),
        .latch_out (encoder_latch_out [iencoder]),

        .adr0  (encoder_adr0 [iencoder]),
        .adr1  (encoder_adr1 [iencoder]),
        .adr2  (encoder_adr2 [iencoder]),
        .adr3  (encoder_adr3 [iencoder]),
        .adr4  (encoder_adr4 [iencoder]),
        .adr5  (encoder_adr5 [iencoder]),
        .adr6  (encoder_adr6 [iencoder]),
        .adr7  (encoder_adr7 [iencoder]),
        .adr8  (encoder_adr8 [iencoder]),
        .adr9  (encoder_adr9 [iencoder]),
        .adr10 (encoder_adr10[iencoder]),
        .adr11 (encoder_adr11[iencoder]),
        .adr12 (encoder_adr12[iencoder]),
        .adr13 (encoder_adr13[iencoder]),
        .adr14 (encoder_adr14[iencoder]),
        .adr15 (encoder_adr15[iencoder]),

        .cnt0  (encoder_cnt0 [iencoder]),
        .cnt1  (encoder_cnt1 [iencoder]),
        .cnt2  (encoder_cnt2 [iencoder]),
        .cnt3  (encoder_cnt3 [iencoder]),
        .cnt4  (encoder_cnt4 [iencoder]),
        .cnt5  (encoder_cnt5 [iencoder]),
        .cnt6  (encoder_cnt6 [iencoder]),
        .cnt7  (encoder_cnt7 [iencoder]),
        .cnt8  (encoder_cnt8 [iencoder]),
        .cnt9  (encoder_cnt9 [iencoder]),
        .cnt10 (encoder_cnt10[iencoder]),
        .cnt11 (encoder_cnt11[iencoder]),
        .cnt12 (encoder_cnt12[iencoder]),
        .cnt13 (encoder_cnt13[iencoder]),
        .cnt14 (encoder_cnt14[iencoder]),
        .cnt15 (encoder_cnt15[iencoder]),

        .vpf0  (encoder_vpf0 [iencoder]),
        .vpf1  (encoder_vpf1 [iencoder]),
        .vpf2  (encoder_vpf2 [iencoder]),
        .vpf3  (encoder_vpf3 [iencoder]),
        .vpf4  (encoder_vpf4 [iencoder]),
        .vpf5  (encoder_vpf5 [iencoder]),
        .vpf6  (encoder_vpf6 [iencoder]),
        .vpf7  (encoder_vpf7 [iencoder]),
        .vpf8  (encoder_vpf8 [iencoder]),
        .vpf9  (encoder_vpf9 [iencoder]),
        .vpf10 (encoder_vpf10[iencoder]),
        .vpf11 (encoder_vpf11[iencoder]),
        .vpf12 (encoder_vpf12[iencoder]),
        .vpf13 (encoder_vpf13[iencoder]),
        .vpf14 (encoder_vpf14[iencoder]),
        .vpf15 (encoder_vpf15[iencoder])
    );
    end
  endgenerate

  wire encoder_latch_or = |encoder_latch_out;

  reg mux_sel_toggle = 0;
  always @(posedge clock4x) begin
    if      (encoder_latch_out[0]) mux_sel_toggle <= 1'b1;
    else if (encoder_latch_out[1]) mux_sel_toggle <= 1'b0;
  end

  wire mux_sel_srl;

  parameter [3:0] mux_sel_dly = 4'd5; // set SRL to 6 for delay of 6; 6+1 (flip-flop) = 7
  SRL16E u_lac_dly (.CLK(clock4x),.CE(1'b1),.D(mux_sel_toggle),.A0(mux_sel_dly[0]),.A1(mux_sel_dly[1]),.A2(mux_sel_dly[2]),.A3(mux_sel_dly[3]),.Q(mux_sel_srl));

  reg mux_sel=0;
  always @(posedge clock4x) begin
    mux_sel <= mux_sel_srl;
  end


  always @(posedge clock4x) begin
      encoder_latch_muxed = mux_sel ? (encoder_latch_out[0])  : (encoder_latch_out[1]);
      
      cnt_muxed[ 0] = mux_sel ? (encoder_cnt0[0])  : (encoder_cnt0 [1]);
      cnt_muxed[ 1] = mux_sel ? (encoder_cnt1[0])  : (encoder_cnt1 [1]);
      cnt_muxed[ 2] = mux_sel ? (encoder_cnt2[0])  : (encoder_cnt2 [1]);
      cnt_muxed[ 3] = mux_sel ? (encoder_cnt3[0])  : (encoder_cnt3 [1]);
      cnt_muxed[ 4] = mux_sel ? (encoder_cnt4[0])  : (encoder_cnt4 [1]);
      cnt_muxed[ 5] = mux_sel ? (encoder_cnt5[0])  : (encoder_cnt5 [1]);
      cnt_muxed[ 6] = mux_sel ? (encoder_cnt6[0])  : (encoder_cnt6 [1]);
      cnt_muxed[ 7] = mux_sel ? (encoder_cnt7[0])  : (encoder_cnt7 [1]);
      cnt_muxed[ 8] = mux_sel ? (encoder_cnt8[0])  : (encoder_cnt8 [1]);
      cnt_muxed[ 9] = mux_sel ? (encoder_cnt9[0])  : (encoder_cnt9 [1]);
      cnt_muxed[10] = mux_sel ? (encoder_cnt10[0]) : (encoder_cnt10[1]);
      cnt_muxed[11] = mux_sel ? (encoder_cnt11[0]) : (encoder_cnt11[1]);
      cnt_muxed[12] = mux_sel ? (encoder_cnt12[0]) : (encoder_cnt12[1]);
      cnt_muxed[13] = mux_sel ? (encoder_cnt13[0]) : (encoder_cnt13[1]);
      cnt_muxed[14] = mux_sel ? (encoder_cnt14[0]) : (encoder_cnt14[1]);
      cnt_muxed[15] = mux_sel ? (encoder_cnt15[0]) : (encoder_cnt15[1]);
      
      adr_muxed[ 0] = mux_sel ? (encoder_adr0[0])  : (encoder_adr0 [1]);
      adr_muxed[ 1] = mux_sel ? (encoder_adr1[0])  : (encoder_adr1 [1]);
      adr_muxed[ 2] = mux_sel ? (encoder_adr2[0])  : (encoder_adr2 [1]);
      adr_muxed[ 3] = mux_sel ? (encoder_adr3[0])  : (encoder_adr3 [1]);
      adr_muxed[ 4] = mux_sel ? (encoder_adr4[0])  : (encoder_adr4 [1]);
      adr_muxed[ 5] = mux_sel ? (encoder_adr5[0])  : (encoder_adr5 [1]);
      adr_muxed[ 6] = mux_sel ? (encoder_adr6[0])  : (encoder_adr6 [1]);
      adr_muxed[ 7] = mux_sel ? (encoder_adr7[0])  : (encoder_adr7 [1]);
      adr_muxed[ 8] = mux_sel ? (encoder_adr8[0])  : (encoder_adr8 [1]);
      adr_muxed[ 9] = mux_sel ? (encoder_adr9[0])  : (encoder_adr9 [1]);
      adr_muxed[10] = mux_sel ? (encoder_adr10[0]) : (encoder_adr10[1]);
      adr_muxed[11] = mux_sel ? (encoder_adr11[0]) : (encoder_adr11[1]);
      adr_muxed[12] = mux_sel ? (encoder_adr12[0]) : (encoder_adr12[1]);
      adr_muxed[13] = mux_sel ? (encoder_adr13[0]) : (encoder_adr13[1]);
      adr_muxed[14] = mux_sel ? (encoder_adr14[0]) : (encoder_adr14[1]);
      adr_muxed[15] = mux_sel ? (encoder_adr15[0]) : (encoder_adr15[1]);
      
      vpf_muxed[ 0] = mux_sel ? (encoder_vpf0[0])  : (encoder_vpf0 [1]);
      vpf_muxed[ 1] = mux_sel ? (encoder_vpf1[0])  : (encoder_vpf1 [1]);
      vpf_muxed[ 2] = mux_sel ? (encoder_vpf2[0])  : (encoder_vpf2 [1]);
      vpf_muxed[ 3] = mux_sel ? (encoder_vpf3[0])  : (encoder_vpf3 [1]);
      vpf_muxed[ 4] = mux_sel ? (encoder_vpf4[0])  : (encoder_vpf4 [1]);
      vpf_muxed[ 5] = mux_sel ? (encoder_vpf5[0])  : (encoder_vpf5 [1]);
      vpf_muxed[ 6] = mux_sel ? (encoder_vpf6[0])  : (encoder_vpf6 [1]);
      vpf_muxed[ 7] = mux_sel ? (encoder_vpf7[0])  : (encoder_vpf7 [1]);
      vpf_muxed[ 8] = mux_sel ? (encoder_vpf8[0])  : (encoder_vpf8 [1]);
      vpf_muxed[ 9] = mux_sel ? (encoder_vpf9[0])  : (encoder_vpf9 [1]);
      vpf_muxed[10] = mux_sel ? (encoder_vpf10[0]) : (encoder_vpf10[1]);
      vpf_muxed[11] = mux_sel ? (encoder_vpf11[0]) : (encoder_vpf11[1]);
      vpf_muxed[12] = mux_sel ? (encoder_vpf12[0]) : (encoder_vpf12[1]);
      vpf_muxed[13] = mux_sel ? (encoder_vpf13[0]) : (encoder_vpf13[1]);
      vpf_muxed[14] = mux_sel ? (encoder_vpf14[0]) : (encoder_vpf14[1]);
      vpf_muxed[15] = mux_sel ? (encoder_vpf15[0]) : (encoder_vpf15[1]);
  end

  wire merge_latch;

  merge16_light u_merge16 (

      .clock4x(clock4x),

      .mux_pulse_in  (encoder_latch_muxed),
      .mux_pulse_out (latch_out),

      .adr_in0  ( adr_muxed[0]),
      .adr_in1  ( adr_muxed[1]),
      .adr_in2  ( adr_muxed[2]),
      .adr_in3  ( adr_muxed[3]),
      .adr_in4  ( adr_muxed[4]),
      .adr_in5  ( adr_muxed[5]),
      .adr_in6  ( adr_muxed[6]),
      .adr_in7  ( adr_muxed[7]),
      .adr_in8  ( adr_muxed[8]),
      .adr_in9  ( adr_muxed[9]),
      .adr_in10 ( adr_muxed[10]),
      .adr_in11 ( adr_muxed[11]),
      .adr_in12 ( adr_muxed[12]),
      .adr_in13 ( adr_muxed[13]),
      .adr_in14 ( adr_muxed[14]),
      .adr_in15 ( adr_muxed[15]),

      .cnt_in0  ( cnt_muxed[0]),
      .cnt_in1  ( cnt_muxed[1]),
      .cnt_in2  ( cnt_muxed[2]),
      .cnt_in3  ( cnt_muxed[3]),
      .cnt_in4  ( cnt_muxed[4]),
      .cnt_in5  ( cnt_muxed[5]),
      .cnt_in6  ( cnt_muxed[6]),
      .cnt_in7  ( cnt_muxed[7]),
      .cnt_in8  ( cnt_muxed[8]),
      .cnt_in9  ( cnt_muxed[9]),
      .cnt_in10 ( cnt_muxed[10]),
      .cnt_in11 ( cnt_muxed[11]),
      .cnt_in12 ( cnt_muxed[12]),
      .cnt_in13 ( cnt_muxed[13]),
      .cnt_in14 ( cnt_muxed[14]),
      .cnt_in15 ( cnt_muxed[15]),

      .vpf_in0  ( vpf_muxed[0]),
      .vpf_in1  ( vpf_muxed[1]),
      .vpf_in2  ( vpf_muxed[2]),
      .vpf_in3  ( vpf_muxed[3]),
      .vpf_in4  ( vpf_muxed[4]),
      .vpf_in5  ( vpf_muxed[5]),
      .vpf_in6  ( vpf_muxed[6]),
      .vpf_in7  ( vpf_muxed[7]),
      .vpf_in8  ( vpf_muxed[8]),
      .vpf_in9  ( vpf_muxed[9]),
      .vpf_in10 ( vpf_muxed[10]),
      .vpf_in11 ( vpf_muxed[11]),
      .vpf_in12 ( vpf_muxed[12]),
      .vpf_in13 ( vpf_muxed[13]),
      .vpf_in14 ( vpf_muxed[14]),
      .vpf_in15 ( vpf_muxed[15]),

      .adr0_o(adr0),
      .adr1_o(adr1),
      .adr2_o(adr2),
      .adr3_o(adr3),
      .adr4_o(adr4),
      .adr5_o(adr5),
      .adr6_o(adr6),
      .adr7_o(adr7),

      .cnt0_o(cnt0),
      .cnt1_o(cnt1),
      .cnt2_o(cnt2),
      .cnt3_o(cnt3),
      .cnt4_o(cnt4),
      .cnt5_o(cnt5),
      .cnt6_o(cnt6),
      .cnt7_o(cnt7)
  );

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
