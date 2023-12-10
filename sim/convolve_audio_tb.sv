`timescale 10ns / 1ps
`default_nettype none

module convolve_audio_tb();

  // Input signals
  logic audio_clk;
  logic rst_in;
  logic audio_trigger;
  logic signed [47:0] convolution_result;
  logic produced_convolutional_result;
  logic [12:0] first_ir_index, second_ir_index;
  logic signed [15:0] ir_vals [7:0]; 
  logic impulse_in_memory_complete;
  logic signed [15:0] audio_in;
  logic ir_data_in_valid, write_enable;
  logic [15:0] ir_sample_index;
  logic signed [15:0] write_data;
  logic filling;

  convolve_audio #(.IMPULSE_LENGTH(24000)) uut_convolve (
                    .audio_clk(audio_clk),
                    .rst_in(rst_in),
                    .audio_trigger(audio_trigger),
                    .audio_in(audio_in),
                    .impulse_in_memory_complete(impulse_in_memory_complete),
                    .convolution_result(convolution_result),
                    .produced_convolutional_result(produced_convolutional_result),
                    .first_ir_index(first_ir_index),
                    .second_ir_index(second_ir_index),
                    .ir_vals(ir_vals)
  );

  ir_buffer #(.MEMORY_DEPTH(16'd6000)) uut_ir (
                    .audio_clk(audio_clk),
                    .rst_in(rst_in),
                    .ir_sample_index(ir_sample_index),
                    .write_data(write_data),
                    .write_enable(write_enable), 
                    .ir_data_in_valid(ir_data_in_valid),
                    .first_ir_index(first_ir_index),
                    .second_ir_index(second_ir_index),   
                    .ir_vals(ir_vals)
    );


  


  // For 98.3 MHz (use an approximately 10.17 ns period) 
  always begin
    #5 audio_clk = !audio_clk; // Half period 
  end

  logic signed [15:0] ir_val_0;
  logic signed [15:0] ir_val_1;
  logic signed [15:0] ir_val_2;
  logic signed [15:0] ir_val_3;
  logic signed [15:0] ir_val_4;
  logic signed [15:0] ir_val_5;
  logic signed [15:0] ir_val_6;
  logic signed [15:0] ir_val_7;

  assign ir_val_0 = ir_vals[0];
  assign ir_val_1 = ir_vals[1];
  assign ir_val_2 = ir_vals[2];
  assign ir_val_3 = ir_vals[3];
  assign ir_val_4 = ir_vals[4];
  assign ir_val_5 = ir_vals[5];
  assign ir_val_6 = ir_vals[6];
  assign ir_val_7 = ir_vals[7];





  initial begin
    $dumpfile("convolve_audio_tb.vcd");
    $dumpvars(0, convolve_audio_tb);
    $display("Starting Simulation");

    // Initialize Inputs
    audio_clk = 0;
    rst_in = 0;
    impulse_in_memory_complete = 0;
    audio_in = 1;
    write_data = 0;
    audio_trigger = 0;

    // Reset sequence
    #25;
    rst_in = 1;
    #20;
    rst_in = 0;
    write_enable = 1;
    filling = 1;
    #10

    for (integer i = 0; i < 24000; i = i +1 ) begin
      audio_trigger = 1;
      audio_in = (i >= 12000);
      #5;
      audio_trigger = 0;
      #5;
    end 
  filling = 0;
    #50;


    for (integer i = 0; i < 24000; i = i +1 ) begin
      ir_sample_index = i;
      //write_data = i % 512;
      write_data = (i >= 12000);
      audio_trigger = 1;
      #1;
      ir_data_in_valid = 1;
      audio_trigger = 0;
      #400;
      ir_data_in_valid = 0;
    end 

    #1;
    write_enable = 0;
    impulse_in_memory_complete = 1;
    #10;
    audio_trigger = 1;
    #1;
    audio_trigger = 0;

    // for (integer i = 0; i < 3003; i = i + 1) begin
    //   if (i < 3000) begin
    //     first_ir_index <= (i << 1);
    //     second_ir_index <= (i << 1) + 1; 
    //   end
    //   #10;
    // end 
    #5000
    
    // // Build the IR values 
    // for (int i = 0; i < 8; i++) begin
    //   ir_vals[i] = 16'd1000;  
    // end


    // impulse_in_memory_complete = 1; // Indicate impulse data is ready
    // #20;
    // for (int i = 0; i < 100; i++) begin
    //   audio_in = 16'd1000;                      //$random;
    //   audio_trigger = 1; // Indicate a new audio sample is ready 
    //   #20;
    //   audio_trigger = 0;
    //   #20;
    // end

    $display("Simulation finished");
    $finish;
  end

endmodule

`timescale 1ns / 1ps
`default_nettype wire
