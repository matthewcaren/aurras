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

  logic sys_rst;

  assign rgb1= 0;
  assign rgb0 = 0;

  logic clk_m;
  audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(clk_m));
  
 // ############################################################## Set up the sound sources - START

  localparam integer COUNTER_MAX = 8192; // This is 2^13, which divides 98.3MHz down to ~12kHz
  logic [12:0] counter; // 13-bit counter to divide down the clock
  logic audio_sample_valid;//single-cycle enable for samples at ~12 kHz (approx)

  always @(posedge clk_m) begin
      if (counter == COUNTER_MAX - 1) begin
        audio_sample_valid <= 1;
        counter <= 0;
      end else begin
        audio_sample_valid <= 0;
        counter <= counter + 1;
      end
    end

  logic [7:0] tone_750; 
  logic [7:0] tone_440; 

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

  // ############################################################## Set up the sound sources - END 
  
  logic sound_out; 
  audio_player ap_1 (
    .clk_in(clk_m),
    .sound_sample_in(tone_750), 
    .signal_out(sound_out),
    .sw(sw)
  );


  assign spkl = sw[0]? sound_out : 0;
  assign spkr = sw[1]? sound_out : 0;

endmodule // top_level


    
    
