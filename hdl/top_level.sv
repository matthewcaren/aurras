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

  // ### CLOCK SETUP

  // 98.3MHz
  logic audio_clk;
  audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(audio_clk)); 

  // This triggers at 48kHz for general audio
  logic audio_trigger;
  logic [10:0] counter;
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

  logic [15:0] raw_audio_in_1, raw_audio_in_2, raw_audio_in_3;
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
  
  // #### INPUT ANTI-ALIASING
  logic [15:0] filter_output_1, filter_output_2, filter_output_3;
  logic [15:0] filtered_audio_in_1, filtered_audio_in_2, filtered_audio_in_3;
  logic filter_valid_1, filter_valid_2, filter_valid_3;
  input_anti_alias_fir anti_alias_filter(.aclk(audio_clk),
                                  .s_axis_data_tvalid(mic_data_vaild_1),
                                  .s_axis_data_tready(1'b1),
                                  .s_axis_data_tdata(raw_audio_in_1),
                                  .m_axis_data_tvalid(filter_valid_1),
                                  .m_axis_data_tdata(filter_output_1));

  always_ff @(posedge audio_clk) begin
    if (filter_valid_1) begin
      filtered_audio_in_1 <= filter_output_1;
    end 
  end

  // ##### SPEED OF SOUND #####

  logic sos_trigger;
  logic last_switch_val;
  logic signed [15:0] sos_audio_out;
  logic [11:0] calculated_delay;
  logic [2:0] sos_state;

  always_ff @(posedge audio_clk) begin
    sos_trigger <= btn[1] & !last_switch_val;
    last_switch_val <= btn[1];
  end

  logic [23:0] last_two; 

  sos_dist_calculator sos_calc(
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .trigger(sos_trigger),
    .mic_in(prefiltered_audio_in_1),
    .amp_out(sos_audio_out),
    .delay(calculated_delay),
    .last_two(last_two));

  /// ### SEVEN SEGMENT DISPLAY
  logic [6:0] ss_c;
  assign ss0_c = ss_c; 
  assign ss1_c = ss_c;
  seven_segment_controller mssc(.clk_in(audio_clk),
                              .rst_in(sys_rst),
                              .val_in({8'b0, last_two}),
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
  logic [15:0] delayed_audio_out; 
  logic sound_out;
  
  assign pdm_in = sw[2] ? {tone_440[7], tone_440[7], tone_440[7], tone_440[7], 
                         tone_440[7], tone_440[7], tone_440[7], tone_440[7], tone_440[7:0]} <<< 8 : 
                    (sw[3] ? prefiltered_audio_in_1 : 
                    (sw[4] ? filtered_audio_in_1 : 
                    (sw[5] ? sos_audio_out : 
                    (sw[6] ? delayed_audio_out : 0))));


  pdm pdm(
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .level_in(pdm_in),
    .pdm_out(sound_out)
  );

  delayed_sound_out my_delayed_sound_out (
    .clk_in(audio_clk), //system clock
    .rst_in(sys_rst),//global reset
    .enable_delay(1'b1), //button indicating whether to record or not
    .audio_valid_in(audio_trigger), //48 khz audio sample valid signal
    .delay_cycle(16'd48000),
    .audio_in(filtered_audio_in_1), //16 bit signed audio data 
    .delayed_audio_out(delayed_audio_out) //played back audio (8 bit signed at 12 kHz)
  );

  assign spkl = sw[0] ? sound_out : 0;
  assign spkr = sw[1] ? sound_out : 0;

endmodule // top_level