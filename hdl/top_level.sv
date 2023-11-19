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

  // I2S MIC PIN ASSIGNMENTS
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
  logic [15:0] prefiltered_audio_in_1
  always_ff @(posedge audio_clk) begin
      if (mic_data_vaild_1) begin
          prefiltered_audio_in_1 <= raw_audio_in_1;
      end
  end
  
  // #### INPUT ANTI-ALIASING
  logic [15:0] filtered_audio_in_1;
  logic filter_valid;
  input_anti_alias_fir anti_alias_filter(.aclk(audio_clk),
                                  .s_axis_data_tvalid(mic_data_vaild_1),
                                  .s_axis_data_tready(1'b1),
                                  .s_axis_data_tdata(raw_audio_in_1),
                                  .m_axis_data_tvalid(filter_valid),
                                  .m_axis_data_tdata(filtered_audio_in_1));

  // ##### SPEED OF SOUND #####

  logic sos_trigger;
  logic last_switch_val;
  logic signed [15:0] sos_audio_out;
  logic [7:0] calculated_delay;
  logic [2:0] sos_state;

  always_ff @(posedge audio_clk) begin
    sos_trigger <= sw[6] & !last_switch_val;
    last_switch_val <= sw[6];
  end

  sos_dist_calculator sos_calc(
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .trigger(sos_trigger),
    .mic_in(prefiltered_audio_in_1),
    .amp_out(sos_audio_out),
    .delay(calculated_delay),
    .current_state(sos_state));

  logic [6:0] ss_c;
  assign ss0_c = ss_c; 
  assign ss1_c = ss_c;
  seven_segment_controller mssc(.clk_in(audio_clk),
                              .rst_in(sys_rst),
                              .val_in({14'b0, sos_state, 8'b0, calculated_delay}),
                              .cat_out(ss_c),
                              .an_out({ss0_an, ss1_an}));

  logic signed [7:0] tone_440; 
  sine_generator sine_440 (
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .amp_out(tone_440)
  ); 
  defparam sine_440.PHASE_INCR = 32'b0000_0100_1011_0001_0111_1110_0100_1011;

  // ############################################################## Set up the sound sources - END 

  
  logic signed [15:0] pdm_in;
  logic sound_out;

  // select sine wave and sign-extend it to 16 bits
  
  assign pdm_in = sw[2] ? {tone_440[7], tone_440[7], tone_440[7], tone_440[7], 
                    tone_440[7], tone_440[7], tone_440[7], tone_440[7], tone_440[7:0]} <<< 8 : 
                    (sw[3] ? prefiltered_audio_in_1 : 
                    (sw[4] ? filtered_audio_in_1 : 
                    (sw[5] ? sos_audio_out : 0)));

  pdm pdm(
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .level_in(pdm_in),
    .pdm_out(sound_out)
  );

  assign spkl = sw[0] ? sound_out : 0;
  assign spkr = sw[1] ? sound_out : 0;

endmodule // top_level