module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire [7:0] pmoda, // Input wires from the mics (data)
    output logic [7:0] pmodb, // Output wires to the mics (clocks)
    input wire [3:0] btn,
    output logic [6:0] ss0_c, ss1_c,
    output logic [3:0] ss0_an, ss1_an,
    output logic [2:0] rgb0, rgb1, //rgb led
    output logic spkl, spkr, //speaker outputs
    output logic [15:0] led, // led outputs
    output logic uart_txd, // if we want to use Manta
    input wire uart_rxd
);

  assign led = sw;
  logic sys_rst;
  assign sys_rst = btn[0];
  assign rgb1 = 0;
  assign rgb0 = 0;

  logic [7:0] DELAY_AMOUNT;
  assign DELAY_AMOUNT = {sw[15:10], 2'b0};

  // ### CLOCK SETUP

  // 98.3MHz
  logic audio_clk;
  audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(audio_clk)); 

  // This triggers at 24kHz for general audio
  logic audio_trigger;
  logic [11:0] counter;
  always_ff @(posedge audio_clk) begin
      counter <= counter + 1;
  end
  assign audio_trigger = (counter == 0);


  // ### MIC INPUT

  // Mic 1: bclk - i2s_clk - pmodb[3]; dout - mic_1_data - pmoda[3]; lrcl_clk - pmodb[2], sel - grounded
  // Mic 2: bclk - i2s_clk - pmodb[7]; dout - mic_2_data - pmoda[7]; lrcl_clk - pmodb[6], sel - grounded
  // Mic 3: bclk - i2s_clk - pmodb[1]; dout - mic_3_data - pmoda[0]; lrcl_clk - pmodb[0], sel - grounded

  logic mic_1_data, mic_2_data, mic_3_data;
  logic i2s_clk_1, i2s_clk_2, i2s_clk_3;
  logic lrcl_clk_1, lrcl_clk_2, lrcl_clk_3;

  logic signed [15:0] raw_audio_in_1, raw_audio_in_2, raw_audio_in_3;
  logic mic_data_vaild_1, mic_data_valid_2, mic_data_valid_3;

  i2s mic_1(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_1_data), .i2s_clk(i2s_clk_1), .lrcl_clk(lrcl_clk_1), .data_valid_out(mic_data_vaild_1), .audio_out(raw_audio_in_1));
  i2s mic_2(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_2_data), .i2s_clk(i2s_clk_2), .lrcl_clk(lrcl_clk_2), .data_valid_out(mic_data_valid_2), .audio_out(raw_audio_in_2));
  i2s mic_3(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_3_data), .i2s_clk(i2s_clk_3), .lrcl_clk(lrcl_clk_3), .data_valid_out(mic_data_valid_3), .audio_out(raw_audio_in_3));

  assign pmodb[3] = i2s_clk_1;
  assign pmodb[7] = i2s_clk_2;
  assign pmodb[1] = i2s_clk_3;

  assign pmodb[2] = lrcl_clk_1;
  assign pmodb[6] = lrcl_clk_2;
  assign pmodb[0] = lrcl_clk_3;

  assign mic_1_data = pmoda[3];
  assign mic_2_data = pmoda[7];
  assign mic_3_data = pmoda[0];

  // Testing prefiltered audio
  logic [15:0] prefiltered_audio_in_1;
  always_ff @(posedge audio_clk) begin
      if (mic_data_vaild_1) begin
        prefiltered_audio_in_1 <= raw_audio_in_1;
      end
  end

   logic signed [15:0] dc_blocked_audio_in_1;
   dc_blocker dc_block(.clk_in(audio_clk),
                      .rst_in(sys_rst),
                      .audio_trigger(audio_trigger),
                      .signal_in(ggggggg),
                      .signal_out(dc_blocked_audio_in_1));

  logic signed [15:0] ggggggg;
  always_ff @(posedge audio_clk) begin
    if (filter_valid_1) begin
      ggggggg <= anti_alias_audio_in_1;
    end
  end 
  
  // #### INPUT ANTI-ALIASING
  logic signed [15:0] anti_alias_audio_in_1, anti_alias_audio_in_2, anti_alias_audio_in_3;
  logic [15:0] final_audio_in_1;
  logic filter_valid_1, filter_valid_2, filter_valid_3;
  input_anti_alias_fir anti_alias_filter(.aclk(audio_clk),
                                  .s_axis_data_tvalid(audio_trigger),
                                  .s_axis_data_tready(1'b1),
                                  .s_axis_data_tdata(prefiltered_audio_in_1),
                                  .m_axis_data_tvalid(filter_valid_1),
                                  .m_axis_data_tdata(anti_alias_audio_in_1));

  logic [15:0] fffff;
  always_ff @(posedge audio_clk) begin
    if (audio_trigger) begin
      fffff <= dc_blocked_audio_in_1;
    end
  end 
  logic every_other; 
  always_ff @(posedge audio_clk) begin
    if (rst_in) begin
      every_other <= 0;
    end
    if (filter_valid_1) begin
      if (every_other == 0) begin
        final_audio_in_1 <= anti_alias_audio_in_1;
      end 
      every_other <= ~(every_other);
    end
  end

  // ##### SPEED OF SOUND #####

  // logic sos_trigger;
  // logic last_switch_val;
  // logic signed [15:0] sos_audio_out;
  // logic [7:0] calculated_delay;
  // logic [2:0] sos_state;

  // always_ff @(posedge audio_clk) begin
  //   sos_trigger <= btn[1] & !last_switch_val;
  //   last_switch_val <= btn[1];
  // end

  // sos_dist_calculator sos_calc(
  //   .clk_in(audio_clk),
  //   .rst_in(sys_rst),
  //   .step_in(audio_trigger),
  //   .trigger(sos_trigger),
  //   .mic_in(prefiltered_audio_in_1),
  //   .amp_out(sos_audio_out),
  //   .delay(calculated_delay));

  // NOT IN USE RIGHT NOW
  
  logic [15:0] displayed_audio;
  always_ff @(posedge audio_clk) begin
    if (btn[2]) begin
      displayed_audio <= final_audio_in_1;
    end 
  end

  localparam impulse_length = 16'd24000;
  logic impulse_recorded;
  logic [11:0] impulse_write_addr;
  logic signed [15:0] impulse_write_data;
  logic signed [47:0] final_convolved_audio;
  logic produced_convolutional_result; 
  logic impulse_write_enable;


  logic convolving;
  logic [11:0] first_ir_index, second_ir_index;
  logic signed [7:0][15:0] ir_vals;

  ir_memory_manager #(16'd3000) impulse_memory(
                                   .audio_clk(audio_clk),
                                   .rst_in(rst_in),
                                   .ir_sample_index(impulse_write_addr),
                                   .write_data(impulse_write_data),
                                   .write_enable(impulse_write_enable),
                                   .first_ir_index(first_ir_index),
                                   .second_ir_index(second_ir_index),
                                   .convolving(convolving),
                                   .ir_vals(ir_vals)
                                   );

  record_impulse #(impulse_length) impulse_recording(
                                   .audio_clk(audio_clk),
                                   .rst_in(rst_in),
                                   .audio_trigger(audio_trigger),
                                   .record_impulse_trigger((btn[3] && sw[8])),
                                   .delay_length(DELAY_AMOUNT),
                                   .audio_in(final_audio_in_1),
                                   .impulse_recorded(impulse_recorded),
                                   .ir_sample_index(impulse_write_addr),
                                   .write_data(impulse_write_data),
                                   .write_enable(impulse_write_enable)
                                   );

  convolve_audio #(impulse_length) convolving_audio(
                                   .audio_clk(audio_clk),
                                   .rst_in(rst_in),
                                   .audio_trigger(audio_trigger),
                                   .audio_in(final_audio_in_1),
                                   .impulse_in_memory_complete(impulse_recorded),
                                   .convolution_result(final_convolved_audio),
                                   .produced_convolutional_result(produced_convolutional_result),
                                   .first_ir_index(first_ir_index),
                                   .second_ir_index(second_ir_index),
                                   .convolving(convolving),
                                   .ir_vals(ir_vals)
                                  );

  logic signed [47:0] displayed_conv_result;
  always_ff @(posedge audio_clk) begin
    if (produced_convolutional_result) begin
      displayed_conv_result <= final_convolved_audio;
    end

  end
  /// ### SEVEN SEGMENT DISPLAY
  logic [6:0] ss_c;
  assign ss0_c = ss_c; 
  assign ss1_c = ss_c;
  seven_segment_controller mssc(.clk_in(audio_clk),
                              .rst_in(sys_rst),
                              .val_in(sw[9] ? displayed_conv_result[31:0] : {DELAY_AMOUNT, 8'h00, displayed_audio}),
                              .cat_out(ss_c),
                              .an_out({ss0_an, ss1_an}));

  // ### TEST SINE WAVE

  logic signed [7:0] tone_440; 
  sine_generator sine_440 (
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .amp_out(tone_440)
  ); 
  defparam sine_440.PHASE_INCR = 32'b0000_0100_1011_0001_0111_1110_0100_1011;

  // ### SOUND OUTPUT MANAGEMENT

  logic signed [15:0] pdm_in;
  logic signed [15:0] delayed_audio_out; 
  logic signed [15:0] one_second_delay;
  logic sound_out;
  
  assign pdm_in = sw[2] ? {tone_440[7], tone_440[7], tone_440[7], tone_440[7], 
                         tone_440[7], tone_440[7], tone_440[7], tone_440[7], tone_440[7:0]} <<< 8 : 
                    (sw[3] ? ggggggg : 
                    (sw[4] ? fffff : 
                  //  (sw[5] ? sos_audio_out : 
                    (sw[6] ? delayed_audio_out : 
                    (sw[7] ? one_second_delay: 0))));


  pdm pdm(
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .level_in(pdm_in),
    .pdm_out(sound_out)
  );


  //Delayed audio by sw[15:10] w/ two 0s tacked on 
  delayed_sound_out #(16'd1000) my_delayed_sound_out (
    .clk_in(audio_clk), //system clock
    .rst_in(sys_rst),//global reset
    .enable_delay(1'b1), //button indicating whether to record or not
    .delay_length(DELAY_AMOUNT),
    .audio_valid_in(audio_trigger), //48 khz audio sample valid signal
    .audio_in(final_audio_in_1), //16 bit signed audio data 
    .delayed_audio_out(delayed_audio_out) //played back audio (8 bit signed at 12 kHz)
  );

  // One second delayed audio
  delayed_sound_out #(16'd24010) one_second_delayed_sound_out (
    .clk_in(audio_clk), //system clock
    .rst_in(sys_rst),//global reset
    .enable_delay(1'b1), //button indicating whether to record or not
    .delay_length(16'd24000),
    .audio_valid_in(audio_trigger), //48 khz audio sample valid signal
    .audio_in(final_audio_in_1), //16 bit signed audio data 
    .delayed_audio_out(one_second_delay) //played back audio (8 bit signed at 12 kHz)
  );

  assign spkl = sw[0] ? sound_out : 0;
  assign spkr = sw[1] ? sound_out : 0;

endmodule // top_level
