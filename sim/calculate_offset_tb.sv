`timescale 10ns / 1ps
`default_nettype none

module calculate_offset_tb();
  // Input signals
  logic audio_clk;
  logic rst_in;
  logic audio_trigger;
  logic offset_trigger;
  logic signed [15:0] audio_in_1, audio_in_2;
  logic signed [15:0] offset_1, offset_2;
  logic offset_produced_1, offset_produced_2;

  calculate_offset uut_1(
                    .audio_clk(audio_clk),
                    .rst_in(rst_in),
                    .audio_trigger(audio_trigger),
                    .offset_trigger(offset_trigger),
                    .audio_in(audio_in_1),
                    .offset(offset_1),
                    .offset_produced(offset_produced_1)
  );

  calculate_offset uut_2(
                    .audio_clk(audio_clk),
                    .rst_in(rst_in),
                    .audio_trigger(audio_trigger),
                    .offset_trigger(offset_trigger),
                    .audio_in(audio_in_2),
                    .offset(offset_2),
                    .offset_produced(offset_produced_2)
  );


  // For 98.3 MHz (use an approximately 10.17 ns period) 
  always begin
    #5 audio_clk = !audio_clk; // Half period 
  end


  initial begin
    $dumpfile("calculate_offset_tb.vcd");
    $dumpvars(0, calculate_offset_tb);
    $display("Starting Simulation");

    // Initialize Inputs
    audio_clk = 0;
    rst_in = 0;
    audio_in_1 = 0;
    audio_in_2 = 0;
    audio_trigger = 0;

    // Reset sequence
    #25;
    rst_in = 1;
    #20;
    rst_in = 0;
    #10
    offset_trigger = 1;
    #10
    offset_trigger = 0;
    #20

    for (integer i = 0; i < 1100; i = i +1 ) begin
      audio_trigger = 1;
      // audio_in_1 = -16'sd8 + (i % 8);
      // audio_in_2 = 16'sd8 + (i % 8);
      audio_in_1 = 16'sd1000 + ($urandom % 200) - 100;
      audio_in_2 = -16'sd1000 + ($urandom % 200) - 100;

      #10;
      audio_trigger = 0;
      #30;
    end 

    #50;

    $display("Simulation finished");
    $finish;
  end

endmodule

`timescale 1ns / 1ps
`default_nettype wire
