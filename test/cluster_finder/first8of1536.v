`timescale 1ns / 100 ps

module cluster_finder (

    input clock,

    input latch_pulse, // this should go high when new vpfs are ready

    input  [MXSBITS*MXVFATS  -1:0] vpfs_in,
    input  [MXSBITS*MXVFATS*3-1:0] cnts_in,

    output reg [2:0]      cnt0,
    output reg [2:0]      cnt1,
    output reg [2:0]      cnt2,
    output reg [2:0]      cnt3,

   `ifndef first4
    output reg [2:0]      cnt4,
   `ifndef first5
    output reg [2:0]      cnt5,
    output reg [2:0]      cnt6,
    output reg [2:0]      cnt7,
   `ifndef first8
    output reg [2:0]      cnt8,
    output reg [2:0]      cnt9,
    output reg [2:0]      cnt10,
    output reg [2:0]      cnt11,
    output reg [2:0]      cnt12,
    output reg [2:0]      cnt13,
    output reg [2:0]      cnt14,
    output reg [2:0]      cnt15,
   `endif
   `endif
   `endif

    output reg [10:0]      adr0,
    output reg [10:0]      adr1,
    output reg [10:0]      adr2,
    output reg [10:0]      adr3,
   `ifndef first4
    output reg [10:0]      adr4,
   `ifndef first5
    output reg [10:0]      adr5,
    output reg [10:0]      adr6,
    output reg [10:0]      adr7,
   `ifndef first8
    output reg [10:0]      adr8,
    output reg [10:0]      adr9,
    output reg [10:0]      adr10,
    output reg [10:0]      adr11,
    output reg [10:0]      adr12,
    output reg [10:0]      adr13,
    output reg [10:0]      adr14,
    output reg [10:0]      adr15,
   `endif
   `endif
   `endif

    output reg vpf0,
    output reg vpf1,
    output reg vpf2,
    output reg vpf3,
   `ifndef first4
    output reg vpf4,
   `ifndef first5
    output reg vpf5,
    output reg vpf6,
    output reg vpf7,
   `ifndef first8
    output reg vpf8,
    output reg vpf9,
    output reg vpf10,
    output reg vpf11,
    output reg vpf12,
    output reg vpf13,
    output reg vpf14,
    output reg vpf15,
   `endif
   `endif
   `endif

    output reg latch_out
);

`include "constants.v"

//----------------------------------------------------------------------------------------------------------------------
// Signals
//----------------------------------------------------------------------------------------------------------------------

`ifdef first4
  parameter NUM_ENCODERS = 1;
  parameter NUM_PASSES   = 4;
`elsif first5
  parameter NUM_ENCODERS = 1;
  parameter NUM_PASSES   = 5;
`elsif first8
  parameter NUM_ENCODERS = 2;
  parameter NUM_PASSES   = 4;
`else
  parameter NUM_ENCODERS = 2;
  parameter NUM_PASSES   = 8;
`endif

  wire [MXSBITS*MXVFATS-1:0] vpfs_truncated;

  wire   [10:0] adr_enc [NUM_ENCODERS-1:0];
  wire   [0:0]  vpf_enc [NUM_ENCODERS-1:0];
  wire   [2:0]  cnt_enc [NUM_ENCODERS-1:0];

//----------------------------------------------------------------------------------------------------------------------
// Encoders
//----------------------------------------------------------------------------------------------------------------------

  reg [MXADRBITS-1:0] adr_latch [NUM_ENCODERS-1:0][NUM_PASSES-1:0];
  reg [MXCNTBITS-1:0] cnt_latch [NUM_ENCODERS-1:0][NUM_PASSES-1:0];
  reg [          0:0] vpf_latch [NUM_ENCODERS-1:0][NUM_PASSES-1:0];

  // carry along a marker showing the ith cluster which is being processed-- used for sync
  wire [2:0] pass_truncate      [NUM_ENCODERS-1:0];
  wire [2:0] pass_encoder       [NUM_ENCODERS-1:0];

  genvar ienc;
  generate
  for (ienc=0; ienc<NUM_ENCODERS; ienc=ienc+1) begin: encloop

      // cluster truncator
      //------------------
      truncate_clusters
      `ifdef first5
      #(.MXSEGS(16))
      `elsif first4
      #(.MXSEGS(16))
      `else
      #(.MXSEGS(12))
      `endif
      u_truncate (
        .clock        (clock),
        .latch_pulse  (latch_pulse),
        .vpfs_in      (vpfs_in       [768*(ienc+1)-1:768*ienc]),
        .vpfs_out     (vpfs_truncated[768*(ienc+1)-1:768*ienc]),
        .pass         (pass_truncate[ienc])
      );

      // 768-bit priority encoder
      //--------------------------
      priority768 u_priority (
        .pass_in       (pass_truncate[ienc]),
        .pass_out      (pass_encoder[ienc]),
        .clock         (clock),       // IN  160 MHz clock
        .latch_pulse   (latch_pulse),
        .vpfs_in       (vpfs_truncated[768  *(ienc+1)-1:768  *ienc]),
        .cnts_in       (cnts_in       [768*3*(ienc+1)-1:768*3*ienc]),
        .cnt           (cnt_enc[ienc]),       // OUT 11-bit counts    of first found cluster
        .adr           (adr_enc[ienc]),       // OUT 11-bit addresses of first found cluster
        .cluster_found (vpf_enc[ienc])
      );

    genvar i;
    for (i=0; i<NUM_PASSES; i=i+1) begin: latchloop
    always @(posedge clock) begin
      if (pass_encoder[ienc]==i) begin
        adr_latch[ienc][i] <= adr_enc[ienc];
        cnt_latch[ienc][i] <= cnt_enc[ienc];
        vpf_latch[ienc][i] <= vpf_enc[ienc];
      end
    end
    end

end
endgenerate

always @(posedge clock) begin
end

reg  [0:0]           vpf_s1 [MXCLUSTERS-1:0];
reg  [MXADRBITS-1:0] adr_s1 [MXCLUSTERS-1:0];
reg  [MXCNTBITS-1:0] cnt_s1 [MXCLUSTERS-1:0];

// latch outputs of priority encoder when it produces its 8 results, stable for merger

always @(posedge clock) begin

  `ifdef first5
      if (pass_encoder[0]==NUM_PASSES-1) begin

          latch_out  <= 1'b1;

          adr_s1  [0]  <= adr_latch[0][0];
          adr_s1  [1]  <= adr_latch[0][1];
          adr_s1  [2]  <= adr_latch[0][2];
          adr_s1  [3]  <= adr_latch[0][3];
          adr_s1  [4]  <= adr_enc  [0]   ; // lookahead

          cnt_s1  [0]  <= cnt_latch[0][0];
          cnt_s1  [1]  <= cnt_latch[0][1];
          cnt_s1  [2]  <= cnt_latch[0][2];
          cnt_s1  [3]  <= cnt_latch[0][3];
          cnt_s1  [4]  <= cnt_enc  [0]   ; // lookahead

          vpf_s1  [0]  <= vpf_latch[0][0];
          vpf_s1  [1]  <= vpf_latch[0][1];
          vpf_s1  [2]  <= vpf_latch[0][2];
          vpf_s1  [3]  <= vpf_latch[0][3];
          vpf_s1  [4]  <= vpf_enc  [0]   ; // lookahead

        end
        else begin
          latch_out  <= 1'b0;
        end
  `elsif first16
        if (pass_encoder[0]==NUM_PASSES-1) begin

            latch_out  <= 1'b1;

          //------------------------------------------------------------------------------------------------------------
          // Address
          //------------------------------------------------------------------------------------------------------------
            adr_s1  [0]  <= adr_latch[0][0];
            adr_s1  [1]  <= adr_latch[0][1];
            adr_s1  [2]  <= adr_latch[0][2];
            adr_s1  [3]  <= adr_latch[0][3];
            adr_s1  [4]  <= adr_latch[0][4];
            adr_s1  [5]  <= adr_latch[0][5];
            adr_s1  [6]  <= adr_latch[0][6];
            adr_s1  [7]  <= adr_enc  [0]   ; // lookahead on #7

            adr_s1  [8]  <= adr_latch[1][0] + (vpf_latch[1][0] * 11'd768);
            adr_s1  [9]  <= adr_latch[1][1] + (vpf_latch[1][1] * 11'd768);
            adr_s1  [10] <= adr_latch[1][2] + (vpf_latch[1][2] * 11'd768);
            adr_s1  [11] <= adr_latch[1][3] + (vpf_latch[1][3] * 11'd768);
            adr_s1  [12] <= adr_latch[1][4] + (vpf_latch[1][4] * 11'd768);
            adr_s1  [13] <= adr_latch[1][5] + (vpf_latch[1][5] * 11'd768);
            adr_s1  [14] <= adr_latch[1][6] + (vpf_latch[1][6] * 11'd768);
            adr_s1  [15] <= adr_enc  [1]    + (vpf_enc  [1]    * 11'd768); // lookahead on #7

          //------------------------------------------------------------------------------------------------------------
          // Count
          //------------------------------------------------------------------------------------------------------------
            cnt_s1  [0]  <= cnt_latch[0][0];
            cnt_s1  [1]  <= cnt_latch[0][1];
            cnt_s1  [2]  <= cnt_latch[0][2];
            cnt_s1  [3]  <= cnt_latch[0][3];
            cnt_s1  [4]  <= cnt_latch[0][4];
            cnt_s1  [5]  <= cnt_latch[0][5];
            cnt_s1  [6]  <= cnt_latch[0][6];
            cnt_s1  [7]  <= cnt_enc  [0]   ; // lookahead on #7

            cnt_s1  [8]  <= cnt_latch[1][0];
            cnt_s1  [9]  <= cnt_latch[1][1];
            cnt_s1  [10] <= cnt_latch[1][2];
            cnt_s1  [11] <= cnt_latch[1][3];
            cnt_s1  [12] <= cnt_latch[1][4];
            cnt_s1  [13] <= cnt_latch[1][5];
            cnt_s1  [14] <= cnt_latch[1][6];
            cnt_s1  [15] <= cnt_enc  [1]   ; // lookahead on #7

          //------------------------------------------------------------------------------------------------------------
          // VPF
          //------------------------------------------------------------------------------------------------------------
            vpf_s1  [0]  <= vpf_latch[0][0];
            vpf_s1  [1]  <= vpf_latch[0][1];
            vpf_s1  [2]  <= vpf_latch[0][2];
            vpf_s1  [3]  <= vpf_latch[0][3];
            vpf_s1  [4]  <= vpf_latch[0][4];
            vpf_s1  [5]  <= vpf_latch[0][5];
            vpf_s1  [6]  <= vpf_latch[0][6];
            vpf_s1  [7]  <= vpf_enc  [0]   ; // lookahead on #7

            vpf_s1  [8]  <= vpf_latch[1][0];
            vpf_s1  [9]  <= vpf_latch[1][1];
            vpf_s1  [10] <= vpf_latch[1][2];
            vpf_s1  [11] <= vpf_latch[1][3];
            vpf_s1  [12] <= vpf_latch[1][4];
            vpf_s1  [13] <= vpf_latch[1][5];
            vpf_s1  [14] <= vpf_latch[1][6];
            vpf_s1  [15] <= vpf_enc  [1]   ; // lookahead on #7

          end
          else begin
              latch_out  <= 1'b0;
          end

       //---------------------------------------------------------------------------------------------------------------
       // First 8 or First4
       //---------------------------------------------------------------------------------------------------------------
     `else
      if (pass_encoder[0]==NUM_PASSES-1) begin

          latch_out  <= 1'b1;

          //------------------------------------------------------------------------------------------------------------
          // Address
          //------------------------------------------------------------------------------------------------------------
          adr_s1  [0]  <= adr_latch[0][0];
          adr_s1  [1]  <= adr_latch[0][1];
          adr_s1  [2]  <= adr_latch[0][2];
          adr_s1  [3]  <= adr_enc  [0]   ; // lookahead on #7

        `ifndef first4
          adr_s1  [4]  <= adr_latch[1][0] + (vpf_latch[1][0] * 11'd768);
          adr_s1  [5]  <= adr_latch[1][1] + (vpf_latch[1][1] * 11'd768);
          adr_s1  [6]  <= adr_latch[1][2] + (vpf_latch[1][2] * 11'd768);
          adr_s1  [7]  <= adr_enc  [1]    + (vpf_enc  [1]    * 11'd768); // lookahead on #7
        `endif

          //------------------------------------------------------------------------------------------------------------
          // Count
          //------------------------------------------------------------------------------------------------------------
          cnt_s1  [0]  <= cnt_latch[0][0];
          cnt_s1  [1]  <= cnt_latch[0][1];
          cnt_s1  [2]  <= cnt_latch[0][2];
          cnt_s1  [3]  <= cnt_enc  [0]   ; // lookahead on #7

        `ifndef first4
          cnt_s1  [4]  <= cnt_latch[1][0];
          cnt_s1  [5]  <= cnt_latch[1][1];
          cnt_s1  [6]  <= cnt_latch[1][2];
          cnt_s1  [7]  <= cnt_enc  [1]   ; // lookahead on #7
        `endif

          //------------------------------------------------------------------------------------------------------------
          // VPF
          //------------------------------------------------------------------------------------------------------------
          vpf_s1  [0]  <= vpf_latch[0][0];
          vpf_s1  [1]  <= vpf_latch[0][1];
          vpf_s1  [2]  <= vpf_latch[0][2];
          vpf_s1  [3]  <= vpf_enc  [0]   ; // lookahead on #7

        `ifndef first4
          vpf_s1  [4]  <= vpf_latch[1][0];
          vpf_s1  [5]  <= vpf_latch[1][1];
          vpf_s1  [6]  <= vpf_latch[1][2];
          vpf_s1  [7]  <= vpf_enc  [1]   ; // lookahead on #7
        `endif

        end
        else begin
          latch_out  <= 1'b0;
        end
  `endif
end

//-------------------------------------------------------------------------------------------------------------------
// Outputs
// ------------------------------------------------------------------------------------------------------------------

`ifdef output_latch
  always @(posedge clock) begin
`else
  always @(*) begin
`endif

    adr0  <= adr_s1[0];
    adr1  <= adr_s1[1];
    adr2  <= adr_s1[2];
    adr3  <= adr_s1[3];

   `ifndef first4
    adr4  <= adr_s1[4];
   `ifndef first5
    adr5  <= adr_s1[5];
    adr6  <= adr_s1[6];
    adr7  <= adr_s1[7];
   `ifndef first8
    adr8  <= adr_s1[8];
    adr9  <= adr_s1[9];
    adr10 <= adr_s1[10];
    adr11 <= adr_s1[11];
    adr12 <= adr_s1[12];
    adr13 <= adr_s1[13];
    adr14 <= adr_s1[14];
    adr15 <= adr_s1[15];
   `endif
   `endif
   `endif

    cnt0  <= cnt_s1[0];
    cnt1  <= cnt_s1[1];
    cnt2  <= cnt_s1[2];
    cnt3  <= cnt_s1[3];

   `ifndef first4
    cnt4  <= cnt_s1[4];
   `ifndef first5
    cnt5  <= cnt_s1[5];
    cnt6  <= cnt_s1[6];
    cnt7  <= cnt_s1[7];
   `ifndef first8
    cnt8  <= cnt_s1[8];
    cnt9  <= cnt_s1[9];
    cnt10 <= cnt_s1[10];
    cnt11 <= cnt_s1[11];
    cnt12 <= cnt_s1[12];
    cnt13 <= cnt_s1[13];
    cnt14 <= cnt_s1[14];
    cnt15 <= cnt_s1[15];
   `endif
   `endif
   `endif

    vpf0  <= vpf_s1[0];
    vpf1  <= vpf_s1[1];
    vpf2  <= vpf_s1[2];
    vpf3  <= vpf_s1[3];

   `ifndef first4
    vpf4  <= vpf_s1[4];
   `ifndef first5
    vpf5  <= vpf_s1[5];
    vpf6  <= vpf_s1[6];
    vpf7  <= vpf_s1[7];
   `ifndef first8
    vpf8  <= vpf_s1[8];
    vpf9  <= vpf_s1[9];
    vpf10 <= vpf_s1[10];
    vpf11 <= vpf_s1[11];
    vpf12 <= vpf_s1[12];
    vpf13 <= vpf_s1[13];
    vpf14 <= vpf_s1[14];
    vpf15 <= vpf_s1[15];
   `endif
   `endif
   `endif
  end

//----------------------------------------------------------------------------------------------------------------------
endmodule
// ---------------------------------------------------------------------------------------------------------------------
