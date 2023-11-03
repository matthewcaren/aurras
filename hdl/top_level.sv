module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    
    input wire [7:0] pmoda, // Tbd how many bits actually needed
    input wire [7:0] pmodb, // Tbd how many bits actually needed
    input wire [3:0] btn,

    output logic spkl, spkr, //speaker outputs
    output logic [15:0] led, // led outputs

    output logic uart_txd, // if we want to use Manta
    input wire uart_rxd,
    output logic mic_clk, //microphone clock
    input wire  mic_data //microphone data

);
    logic [1:0] mic_select;

    // assign mic_select = sw[15:14];
    // always_comb begin
    //     case (mic_select)
    //         2'b10: // Select mic 1
    //         2'b11: // Select mic 2
    //         2'b00: // Select mic 3
    //         default: 
    //     endcase
    // end


  logic clk_m;
  audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(clk_m)); //98.3MHz
  // we make 98.3 MHz since that number is cleanly divisible by
  // 32 to give us 3.072 MHz.  3.072 MHz is nice because it is cleanly divisible
  // by nice powers of 2 to give us reasonable audio sample rates. For example,
  // a decimation by a factor of 64 could give us 6 bit 48 kHz audio
  // a decimation by a factor of 256 gives us 8 bit 12 kHz audio
  //we do the latter in this lab.


  logic record; //signal used to trigger recording
  //definitely want this debounced:
  debouncer rec_deb(  .clk_in(clk_m),
                      .rst_in(sys_rst),
                      .dirty_in(btn[1]),
                      .clean_out(record));

  //logic for controlling PDM associated modules:
  logic [8:0] m_clock_counter; //used for counting for mic clock generation
  logic audio_sample_valid;//single-cycle enable for samples at ~12 kHz (approx)
  logic signed [7:0] mic_audio; //audio from microphone 8 bit unsigned at 12 kHz
  logic[7:0] audio_data; //raw scaled audio data

  //logic for interfacing with the microphone and generating 3.072 MHz signals
  logic [7:0] pdm_tally;
  logic [8:0] pdm_counter;

  localparam PDM_COUNT_PERIOD = 32; //do not change
  localparam NUM_PDM_SAMPLES = 256; //number of pdm in downsample/decimation/average

  logic old_mic_clk; //prior mic clock for edge detection
  logic sampled_mic_data; //one bit grabbed/held values of mic
  logic pdm_signal_valid; //single-cycle signal at 3.072 MHz indicating pdm steps

  assign pdm_signal_valid = mic_clk && ~old_mic_clk;


  //logic to produce 25 MHz step signal for PWM module
  logic [1:0] pwm_counter;
  logic pwm_step; //single-cycle pwm step
  assign pwm_step = (pwm_counter==2'b11);

  always_ff @(posedge clk_m)begin
    pwm_counter <= pwm_counter+1;
  end

  //generate clock signal for microphone
  //microphone signal at ~3.072 MHz
  always_ff @(posedge clk_m)begin
    mic_clk <= m_clock_counter < PDM_COUNT_PERIOD/2;
    m_clock_counter <= (m_clock_counter==PDM_COUNT_PERIOD-1)?0:m_clock_counter+1;
    old_mic_clk <= mic_clk;
  end
  
  //generate audio signal (samples at ~12 kHz
  always_ff @(posedge clk_m)begin
    if (pdm_signal_valid)begin
      sampled_mic_data    <= mic_data;
      pdm_counter         <= (pdm_counter==NUM_PDM_SAMPLES)?0:pdm_counter + 1;
      pdm_tally           <= (pdm_counter==NUM_PDM_SAMPLES)?mic_data
                                                            :pdm_tally+mic_data;
      audio_sample_valid  <= (pdm_counter==NUM_PDM_SAMPLES);
      mic_audio           <= (pdm_counter==NUM_PDM_SAMPLES)?{~pdm_tally[7],pdm_tally[6:0]}
                                                            :mic_audio;
    end else begin
      audio_sample_valid <= 0;
    end
  end

  logic [7:0] tone_750; //output of sine wave of 750Hz
  logic [7:0] tone_440; //output of sine wave of 440 Hz
  logic [7:0] single_audio; //recorder non-echo output
  logic [7:0] echo_audio; //recorder echo output

  // //generate a 750 Hz tone
  // assign tone_750 = 0; //replace and make instance of sine_generator for 750Hz
  // //generate a 440 Hz tone
  // assign tone_440 = 0; //replace and make instance of sine generator for 440 Hz


  sine_generator sine_750 (
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .step_in(audio_sample_valid),
    .amp_out(tone_750)
  ); 

  sine_generator sine_440 (
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .step_in(audio_sample_valid),
    .amp_out(tone_440)
  ); 

  defparam sine_440.PHASE_INCR = 32'b1001_0110_0010_1111_1100_1001_0110;
  //2^32/(12000/440) = 157,482,134.2 

  recorder my_recorder(
    .clk_in(clk_m), //system clock
    .rst_in(sys_rst),//global reset
    .record_in(record), //button indicating whether to record or not
    .audio_valid_in(audio_sample_valid), //12 kHz audio sample valid signal
    .audio_in(mic_audio), //8 bit signed data from microphone
    .single_out(single_audio), //played back audio (8 bit signed at 12 kHz)
    .echo_out(echo_audio) //played back audio (8 bit signed at 12 kHz)
  );


  //choose which signal to play:
  logic [7:0] audio_data_sel;

  always_comb begin
    if (sw[0])begin
      audio_data_sel = tone_750; //signed
    end else if (sw[1])begin
      audio_data_sel = tone_440; //signed
    end else if (sw[5])begin
      audio_data_sel = mic_audio; //signed
    end else if (sw[6])begin
      audio_data_sel = single_audio; //signed
    end else if (sw[7])begin
      audio_data_sel = echo_audio; //signed
    end else begin
      audio_data_sel = mic_audio; //signed
    end
  end


  logic signed [7:0] vol_out; //can be signed or not signed...doesn't really matter
  // all this does is convey the output of vol_out to the input of the pdm
  // since it isn't used directly with any sort of math operation its signedness
  // is not as important.
  volume_control vc (.vol_in(sw[15:13]),.signal_in(audio_data_sel), .signal_out(vol_out));

  //PWM:
  logic pwm_out_signal; //an inherently digital signal (0 or 1..no need to make signed)
  //the "value" is encoded using Pulse Width Modulation
  //PDM:
  logic pdm_out_signal; //an inherently digital signal (0 or 1..no need to make signed)
  //the value is encoded using Pulse Density Modulation
  logic audio_out; //value that drives output channels directly

  //already implemented for you:
  pwm my_pwm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pwm_step),
    .pwm_out(pwm_out_signal)
  );

  //you build (currently empty):
  pdm my_pdm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pdm_signal_valid),
    .pdm_out(pdm_out_signal)
  );

  always_comb begin
    case (sw[4:3])
      2'b00: audio_out = pwm_out_signal;
      2'b01: audio_out = pdm_out_signal;
      2'b10: audio_out = sampled_mic_data;
      2'b11: audio_out = 0;
    endcase
  end

  assign spkl = audio_out;
  assign spkr = audio_out;

endmodule // top_level

//Volume Control
module volume_control (
  input wire [2:0] vol_in,
  input wire signed [7:0] signal_in,
  output logic signed [7:0] signal_out);
    logic [2:0] shift;
    assign shift = 3'd7 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule


    

    
    
