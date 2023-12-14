module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire [7:0] pmoda, // Input wires from the mics (data)
    output logic [7:0] pmodb, // Output wires to the mics (clocks)
    input wire [3:0] btn,
    output logic [6:0] ss0_c, ss1_c,
    output logic [3:0] ss0_an, ss1_an,
    output logic [2:0] rgb0, rgb1, 
    output logic spkl, spkr, 
    output logic [15:0] led
);

  assign led = sw;
  logic sys_rst;
  assign sys_rst = btn[0];
  assign rgb1 = 0;
  assign rgb0 = 0;

  logic [5:0] DELAY_AMOUNT;
  assign DELAY_AMOUNT = {sw[15:10]};

  // ### CLOCK SETUP

  // 98.3MHz
  logic audio_clk;
  audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(audio_clk)); 

  // This triggers at 24kHz for general audio
  logic audio_trigger;
  logic [11:0] audio_trigger_counter;
  always_ff @(posedge audio_clk) begin
      audio_trigger_counter <= audio_trigger_counter + 1;
  end
  assign audio_trigger = (audio_trigger_counter == 0);


  // ### MIC INPUT

  // Mic 1: bclk - i2s_clk - pmodb[3]; dout - mic_data_system - pmoda[3]; lrcl_clk - pmodb[2], sel - grounded
  // Mic 2: bclk - i2s_clk - pmodb[7]; dout - mic_data_calibrate - pmoda[7]; lrcl_clk - pmodb[6], sel - grounded

  logic mic_data_system, mic_data_calibrate;
  logic i2s_clk_system, i2s_clk_calibrate;
  logic lrcl_clk_system, lrcl_clk_calibrate;
  logic signed [15:0] raw_audio_in_system_singlecycle, raw_audio_in_calibrate_singlecycle;
  logic signed [15:0] raw_audio_in_system, raw_audio_in_calibrate;
  logic signed [15:0] processed_audio_in_system, processed_audio_in_calibrate;
  logic signed [15:0] intermediate_audio_val_system, intermediate_audio_val_calibrate;
  logic mic_data_valid_system, mic_data_valid_calibrate;

  i2s mic_system(
        .audio_clk(audio_clk),
        .rst_in(sys_rst), 
        .mic_data(mic_data_system), 
        .i2s_clk(i2s_clk_system), 
        .lrcl_clk(lrcl_clk_system), 
        .data_valid_out(mic_data_valid_system), 
        .audio_out(raw_audio_in_system_singlecycle));

  i2s mic_calibrate(
        .audio_clk(audio_clk), 
        .rst_in(sys_rst),
        .mic_data(mic_data_calibrate),
        .i2s_clk(i2s_clk_calibrate),
        .lrcl_clk(lrcl_clk_calibrate),
        .data_valid_out(mic_data_valid_calibrate),
        .audio_out(raw_audio_in_calibrate_singlecycle));

  assign pmodb[3] = i2s_clk_system;
  assign pmodb[7] = i2s_clk_calibrate;
  assign pmodb[2] = lrcl_clk_system;
  assign pmodb[6] = lrcl_clk_calibrate;
  assign mic_data_system = pmoda[3];
  assign mic_data_calibrate = pmoda[7];

  logic debounced_btn_1;
  debouncer debouncer_system (
				.clk_in(audio_clk),
				.rst_in(sys_rst),
				.dirty_in(btn[1]),
				.clean_out(debounced_btn_1));

  process_audio process_mic_system(
        .audio_clk(audio_clk),
        .rst_in(sys_rst),
        .offset_trigger(debounced_btn_1),
        .mic_data_valid(mic_data_valid_system),
        .raw_audio_single_cycle(raw_audio_in_system_singlecycle),
        .raw_audio_in(raw_audio_in_system),
        .intermediate_audio_val(intermediate_audio_val_system),
        .processed_audio(processed_audio_in_system));

  process_audio process_mic_calibrate(
        .audio_clk(audio_clk),
        .rst_in(sys_rst),
        .offset_trigger(debounced_btn_1),
        .mic_data_valid(mic_data_valid_calibrate),
        .raw_audio_single_cycle(raw_audio_in_calibrate_singlecycle),
        .raw_audio_in(raw_audio_in_calibrate),
        .intermediate_audio_val(intermediate_audio_val_calibrate),
        .processed_audio(processed_audio_in_calibrate));

  logic signed [15:0] unconvolved_audio_system;
  assign unconvolved_audio_system = (-16'sd1 * processed_audio_in_system);


  localparam impulse_length = 16'd24000;
  logic impulse_recorded, able_to_impulse, produced_convolutional_result, impulse_write_enable;
  logic [15:0] impulse_write_addr;
  logic signed [15:0] impulse_response_write_data, impulse_amp_out;
  logic signed [47:0] convolved_audio_system_singlecycle;
  logic [12:0] first_ir_index, second_ir_index;
  logic signed [15:0] ir_vals [7:0];
  logic ir_data_in_valid;

  ir_buffer #(16'd6000) impulse_memory(
        .audio_clk(audio_clk),
        .rst_in(sys_rst),
        .ir_sample_index(impulse_write_addr),
        .write_data(impulse_response_write_data),
        .write_enable(impulse_write_enable),
        .ir_data_in_valid(ir_data_in_valid),
        .first_ir_index(first_ir_index),
        .second_ir_index(second_ir_index),
        .ir_vals(ir_vals));

  record_impulse #(impulse_length) impulse_recording(
        .audio_clk(audio_clk),
        .rst_in(sys_rst),
        .audio_trigger(audio_trigger),
        .record_impulse_trigger(btn[3]),
        .delay_length(DELAY_AMOUNT),
        .audio_in(processed_audio_in_calibrate),
        .impulse_recorded(impulse_recorded),
        .ir_sample_index(impulse_write_addr),
        .ir_data_in_valid(ir_data_in_valid),
        .write_data(impulse_response_write_data),
        .write_enable(impulse_write_enable),
        .impulse_amp_out(impulse_amp_out));

  convolve_audio #(impulse_length) convolving_audio(
        .audio_clk(audio_clk),
        .rst_in(sys_rst),
        .audio_trigger(audio_trigger),
        .audio_in(processed_audio_in_system),
        .impulse_in_memory_complete(impulse_recorded),
        .convolution_result(convolved_audio_system_singlecycle),
        .produced_convolutional_result(produced_convolutional_result),
        .first_ir_index(first_ir_index),
        .second_ir_index(second_ir_index),
        .ir_vals(ir_vals));  
  
  logic signed [15:0] convolved_audio_system;
  always_ff @(posedge audio_clk) begin
    if (produced_convolutional_result) begin
      convolved_audio_system <= (-16'sd1 * convolved_audio_system_singlecycle[28:13]);
    end
  end

  // ### TEST SINE WAVE

  logic signed [7:0] tone_440; 
  sine_generator sine_440 (
        .clk_in(audio_clk),
        .rst_in(sys_rst),
        .step_in(audio_trigger),
        .amp_out(tone_440)); 
  defparam sine_440.PHASE_INCR = 32'b0000_0100_1011_0001_0111_1110_0100_1011;

  // ### Allpass speaker phase correction
  logic allpassed_system_valid_convolved;
  logic signed [15:0] allpassed_system_singlecycle_convolved, allpassed_system_convolved;
  fir_allpass_24k_16width_output allpass_system_convolved (
        .aclk(audio_clk),
        .s_axis_data_tvalid(audio_trigger),
        .s_axis_data_tready(1'b1),
        .s_axis_data_tdata(convolved_audio_system),
        .m_axis_data_tvalid(allpassed_system_valid_convolved),
        .m_axis_data_tdata(allpassed_system_singlecycle_convolved));
  always_ff @(posedge audio_clk) begin
    if (allpassed_system_valid_convolved) begin
      allpassed_system_convolved <= allpassed_system_singlecycle_convolved;
    end 
  end

  logic allpassed_system_valid_unconvolved;
  logic signed [15:0] allpassed_system_singlecycle_unconvolved, allpassed_system_unconvolved;
  fir_allpass_24k_16width_output allpass_system_unconvolved (
        .aclk(audio_clk),
        .s_axis_data_tvalid(audio_trigger),
        .s_axis_data_tready(1'b1),
        .s_axis_data_tdata(unconvolved_audio_system),
        .m_axis_data_tvalid(allpassed_system_valid_unconvolved),
        .m_axis_data_tdata(allpassed_system_singlecycle_unconvolved));
  always_ff @(posedge audio_clk) begin
    if (allpassed_system_valid_unconvolved) begin
      allpassed_system_unconvolved <= allpassed_system_singlecycle_unconvolved;
    end 
  end

  logic signed [15:0] delayed_convolved_audio_out_system, delayed_unconvolved_audio_out_system, one_second_delay;
  //Delayed audio by sw[15:10] w/ two 0s tacked on 
  delay_audio #(16'd1000) delay_convolved_audio_system (
        .clk_in(audio_clk), 
        .rst_in(sys_rst),
        .enable_delay(1'b1), 
        .delay_length(DELAY_AMOUNT - 3'd1),
        .audio_valid_in(audio_trigger), 
        .audio_in(allpassed_system_convolved), 
        .delayed_audio_out(delayed_convolved_audio_out_system));

  //Delayed audio by sw[15:10] w/ two 0s tacked on 
  delay_audio #(16'd1000) delay_unconvolved_audio_system (
        .clk_in(audio_clk), 
        .rst_in(sys_rst),
        .enable_delay(1'b1), 
        .delay_length(DELAY_AMOUNT),
        .audio_valid_in(audio_trigger), 
        .audio_in(allpassed_system_unconvolved), 
        .delayed_audio_out(delayed_unconvolved_audio_out_system));

  // One second delayed audio
  delay_audio #(16'd24010) one_second_delayed_sound_out (
        .clk_in(audio_clk),
        .rst_in(sys_rst),
        .enable_delay(1'b1), 
        .delay_length(16'd24000),
        .audio_valid_in(audio_trigger),
        .audio_in(processed_audio_in_system),
        .delayed_audio_out(one_second_delay) 
  );

  // ### SOUND OUTPUT MANAGEMENT

  logic signed [15:0] pdm_out_system;
  logic sound_out_system, sound_out_calibrate;
  
  assign pdm_out_system = sw[2] ? {{8{tone_440[7]}}, tone_440[7:0]} <<< 8 : 
                    (sw[3] ? raw_audio_in_system : 
                    (sw[4] ? processed_audio_in_system : 
                    (sw[5] ? intermediate_audio_val_system :
                    (sw[6] ? delayed_convolved_audio_out_system : 
                    (sw[7] ? delayed_unconvolved_audio_out_system : 
                    (sw[8] ? one_second_delay : 0))))));

  pdm pdm_calibrate(
        .clk_in(audio_clk),
        .rst_in(sys_rst),
        .level_in(impulse_amp_out),
        .pdm_out(sound_out_calibrate));

  pdm pdm_system(
        .clk_in(audio_clk),
        .rst_in(sys_rst),
        .level_in(pdm_out_system + 16'sd2000),
        .pdm_out(sound_out_system));

  assign spkl = sw[0] ? sound_out_calibrate : 0;
  assign spkr = sw[1] ? sound_out_system : 0;


  /// ### SEVEN SEGMENT DISPLAY

  logic signed [15:0] displayed_audio_left, displayed_audio_right;
  always_ff @(posedge audio_clk) begin
    if (btn[2]) begin
      displayed_audio_left <= pdm_out_system;
      displayed_audio_right <= (sw[9] ? raw_audio_in_system : processed_audio_in_system);
    end
  end

  logic [6:0] ss_c;
  assign ss0_c = ss_c; 
  assign ss1_c = ss_c;

  seven_segment_controller mssc(
        .clk_in(audio_clk),
        .rst_in(sys_rst),
        .val_in({displayed_audio_left, displayed_audio_right}),
        .cat_out(ss_c),
        .an_out({ss0_an, ss1_an}));
        
endmodule
