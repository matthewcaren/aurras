`timescale 1ns / 1ps
`default_nettype none

module i2s_tb();
  logic clk_in;
  logic rst_in;
  logic lrcl_clk;
  logic i2s_clk;
  logic mic_data;
  logic data_valid_out;
  logic [63:0] audio_out;

  i2s uut
          ( .audio_clk(clk_in),
            .rst_in(rst_in),
            .mic_data(mic_data),
            .lrcl_clk(lrcl_clk),
            .i2s_clk(i2s_clk),
            .data_valid_out(data_valid_out),
            .audio_out(audio_out)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end

initial begin
    $dumpfile("i2s_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,i2s_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    mic_data = 1;
    #100000;
    $display("Simulation finished");
    $finish;
end

endmodule

`default_nettype wire
