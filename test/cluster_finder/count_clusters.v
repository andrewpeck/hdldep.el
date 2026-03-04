module count_clusters (
    input clock4x,

    input  [1535:0] vpfs_i,

    output reg [10:0] cnt_o,

    output reg overflow_o
);

  reg [2:0] cnt_s1 [255:0]; // count to 6
  reg [3:0] cnt_s2 [127:0]; // count to 12
  reg [4:0] cnt_s3  [63:0]; // count to 24
  reg [5:0] cnt_s4  [31:0]; // count to 48
  reg [6:0] cnt_s5  [15:0]; // count to 96
  reg [8:0] cnt_s6  [ 7:0]; // count to 192
  reg [9:0] cnt_s7  [ 1:0]; // count to 768

  reg [10:0] cnt; // count to 1536

  // register inputs
  // make sure Xilinx doesn't merge these with copies in the cluster finding
  // flop twice for easier fanout
  (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
  reg  [1535:0] vpfs;
  (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
  reg  [1535:0] vpfs_s0;

  always @(posedge clock4x) begin
    vpfs_s0 <= vpfs_i;
    vpfs    <= vpfs_s0;
  end

  genvar icnt;

  generate
  for (icnt=0; icnt<(256); icnt=icnt+1) begin: cnt_s1_loop
    always @(posedge clock4x)
      cnt_s1[icnt] <= fast6count(vpfs[(icnt+1)*6-1:icnt*6]);
  end
  endgenerate

  generate
  for (icnt=0; icnt<(128); icnt=icnt+1) begin: cnt_s2_loop
    always @(posedge clock4x)
        cnt_s2[icnt] <= cnt_s1[(icnt+1)*2-1] + cnt_s1[icnt*2];
  end
  endgenerate

  generate
  for (icnt=0; icnt<(64); icnt=icnt+1) begin: cnt_s3_loop
    always @(posedge clock4x)
      cnt_s3[icnt] <= cnt_s2[(icnt+1)*2-1] + cnt_s2[icnt*2];
  end
  endgenerate

  generate
  for (icnt=0; icnt<(32); icnt=icnt+1) begin: cnt_s4_loop
    always @(posedge clock4x)
      cnt_s4[icnt] <= cnt_s3[(icnt+1)*2-1] + cnt_s3[icnt*2];
  end
  endgenerate

  generate
  for (icnt=0; icnt<(16); icnt=icnt+1) begin: cnt_s5_loop
    always @(posedge clock4x)
      cnt_s5[icnt] <= cnt_s4[(icnt+1)*2-1] + cnt_s4[icnt*2];
  end
  endgenerate

  generate
  for (icnt=0; icnt<(8); icnt=icnt+1) begin: cnt_s6_loop
    always @(posedge clock4x)
      cnt_s6[icnt] <= cnt_s5[(icnt+1)*2-1] + cnt_s5[icnt*2];
  end
  endgenerate

  always @(posedge clock4x) begin
    cnt_s7[0] <= cnt_s6[0]  + cnt_s6[1]  + cnt_s6[2]  + cnt_s6[3];
    cnt_s7[1] <= cnt_s6[4]  + cnt_s6[5]  + cnt_s6[6]  + cnt_s6[7];
  end

  always @(posedge clock4x) begin
    cnt <=  cnt_s7[0] + cnt_s7[1];
    cnt_o <= cnt;
    overflow_o <= (cnt > 8);
  end


  function [2:0] fast6count;  // do a fast count of 6 bits with just 3 LUTs (the best you can do in a single logic step)
  input [5:0] s;
  begin
      // an odd number of bits are High, will always turn on the lowest bit of the counter
      fast6count[0] = ^s[5:0];

      fast6count[1] = // all 6 bits are High, or exactly 3, or exactly 2
                        s==6'b111111 |
                        // set 3 out of 6, 20 ways:
                        ( s==6'b000111 | s==6'b111000 | s==6'b001011 | s==6'b001101 | s==6'b001110  |  s==6'b010011 | s==6'b010101 | s==6'b010110  |  s==6'b100011 | s==6'b100101 | s==6'b100110 | s==6'b011001 | s==6'b011010 | s==6'b011100  |  s==6'b101001 | s==6'b101010 | s==6'b101100  |  s==6'b110001 | s==6'b110010 | s==6'b110100 ) |
                        // set 2 out of 6, 15 ways:
                        ( s==6'b000011 | s==6'b000101 | s==6'b000110  |  s==6'b001001 | s==6'b001010 | s==6'b001100  | s==6'b010001 | s==6'b010010 | s==6'b010100 | s==6'b011000 | s==6'b100001 | s==6'b100010 | s==6'b100100 | s==6'b101000 | s==6'b110000 );

      fast6count[2] = // all 6 are High, or exactly 4, or exactly 5
                        s==6'b111111 |
                        // set 4 out of 6, 15 ways:
                        ( s==6'b111100 | s==6'b111010 | s==6'b111001  |  s==6'b110110 | s==6'b110101 | s==6'b110011  | s==6'b101110 | s==6'b101101 | s==6'b101011 | s==6'b100111 | s==6'b011110 | s==6'b011101 | s==6'b011011 | s==6'b010111 | s==6'b001111 ) |
                        // set 5 out of 6, just 6 ways:
                        ( s==6'b111110 | s==6'b111101 | s==6'b111011  |  s==6'b110111 | s==6'b101111 | s==6'b011111 );
  end
  endfunction

endmodule
