
// overcome limitation that the Spartan-6 and prior generations to not allow routing a clock into logic, but we can replicate it with a
// "logic accessible clock" which is recovered from the clock but available on the fabric

module lac (
  input clock, // 40 MHz clock
  input clock4x,
  input clock5x,
  output clock_lac, // 180 degree 40MHz clock
  output strobe4x, // goes high on rising edge of clock_lac
  output strobe5x
);

reg lac_pos=0;
reg lac_neg=0;

(* max_fanout = 16 *) reg strobe_int_4x;
(* max_fanout = 16 *) reg rising_edge_5x;
(* max_fanout = 16 *) wire clock_lac_int;

always @(posedge clock) lac_pos <= ~lac_pos;
always @(negedge clock) lac_neg <= ~lac_neg;

assign clock_lac_int = lac_pos ^ lac_neg;

assign clock_lac = clock_lac_int;
assign strobe4x    = strobe_int_4x;
assign strobe5x    = rising_edge_5x;

reg [3:0] clock_sampled_4x;
always @(posedge clock4x) begin
  clock_sampled_4x <= {clock_sampled_4x[2:0], clock_lac};
  strobe_int_4x    <= (clock_sampled_4x==4'b0110);
end


reg clock_sampled_5x;
always @(posedge clock5x) begin

  clock_sampled_5x <= clock_lac;

  if (clock_lac && !clock_sampled_5x) rising_edge_5x <= 1'b1;
  else                                rising_edge_5x <= 1'b0;

end



endmodule
