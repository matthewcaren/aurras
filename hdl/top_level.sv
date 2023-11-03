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
    input wire  mic_data, //microphone data
    output logic [2:0] rgb0, //rgb led
    output logic [2:0] rgb1 //rgb led

);

    assign rgb1= 0;
    assign rgb0 = 0;
    // logic [1:0] mic_select;

    // assign mic_select = sw[15:14];
    // always_comb begin
    //     case: (mic_select)
    //         2'b10: // Select mic 1
    //         2'b11: // Select mic 2
    //         2'b00: // Select mic 3
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


  //logic for controlling PDM associated modules:

  logic audio_sample_valid;//single-cycle enable for samples at ~12 kHz (approx)
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


  localparam integer COUNTER_MAX = 8192; // This is 2^13, which divides 98.3MHz down to ~12kHz
  logic [12:0] counter; // 13-bit counter to divide down the clock

  always @(posedge clk_m) begin
      if (counter == COUNTER_MAX - 1) begin
        audio_sample_valid <= 1;
        counter <= 0;
      end else begin
        audio_sample_valid <= 0;
        counter <= counter + 1;
      end
    end

  logic [7:0] tone_750; //output of sine wave of 750Hz
  logic [7:0] tone_440; //output of sine wave of 440 Hz

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


  //choose which signal to play:
  logic [7:0] audio_data_sel;

  always_comb begin
    if (sw[0])begin
      audio_data_sel = tone_750; //signed
    end else if (sw[1])begin
      audio_data_sel = tone_440; //signed
    end
  end


  logic signed [7:0] vol_out;
  volume_control vc (.vol_in(sw[15:13]),.signal_in(audio_data_sel), .signal_out(vol_out));

  logic pwm_out_signal;

  pwm my_pwm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pwm_step),
    .pwm_out(pwm_out_signal)
  );

 
  assign spkl = pwm_out_signal;
  assign spkr = pwm_out_signal;

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


    

    
    
