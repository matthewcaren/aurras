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

    // This triggers at 24kHz for general audio
    logic audio_trigger;
    logic [11:0] counter;
    always_ff @(posedge audio_clk) begin
        counter <= counter + 1;
    end
    assign audio_trigger = (counter == 0);

    /*

    // Mic 1: bclk - i2s_clk - pmodb[3]; dout - mic_1_data - pmoda[3]; lrcl_clk - pmodb[2], sel - grounded
    // Mic 2: bclk - i2s_clk - pmodb[7]; dout - mic_2_data - pmoda[7]; lrcl_clk - pmodb[6], sel - grounded
    // Mic 3: bclk - i2s_clk - pmodb[1]; dout - mic_3_data - pmoda[0]; lrcl_clk - pmodb[0], sel - grounded

    logic mic_1_data, mic_2_data, mic_3_data;
    logic i2s_clk_1, i2s_clk_2, i2s_clk_3;
    logic lrcl_clk_1, lrcl_clk_2, lrcl_clk_3;
    logic [15:0] audio_out_1, audio_out_2, audio_out_3;
    logic data_valid_out_1, data_valid_out_2, data_valid_out_3;

    i2s mic_1(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_1_data), .i2s_clk(i2s_clk_1), .lrcl_clk(lrcl_clk_1), .data_valid_out(data_valid_out_1), .audio_out(audio_out_1));
    i2s mic_2(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_2_data), .i2s_clk(i2s_clk_2), .lrcl_clk(lrcl_clk_2), .data_valid_out(data_valid_out_2), .audio_out(audio_out_2));
    i2s mic_3(.audio_clk(audio_clk), .rst_in(sys_rst), .mic_data(mic_3_data), .i2s_clk(i2s_clk_3), .lrcl_clk(lrcl_clk_3), .data_valid_out(data_valid_out_3), .audio_out(audio_out_3));

    assign pmodb[3] = i2s_clk_1;
    assign pmodb[7] = i2s_clk_2;
    assign pmodb[1] = i2s_clk_3;

    assign pmodb[2] = lrcl_clk_1;
    assign pmodb[6] = lrcl_clk_2;
    assign pmodb[0] = lrcl_clk_3;

    assign mic_1_data = pmoda[3];
    assign mic_2_data = pmoda[7];
    assign mic_3_data = pmoda[0];


    logic [15:0] valid_audio_out_1, valid_audio_out_2, valid_audio_out_3;
    always_ff @(posedge audio_clk) begin
        if (data_valid_out_1) begin
            valid_audio_out_1 <= audio_out_1;
        end
        // if (data_valid_out_2) begin
        //     valid_audio_out_2 <= audio_out_2;
        // end
        // if (data_valid_out_3) begin
        //     valid_audio_out_3 <= audio_out_3;
        // end
    end


    // seven segment display - display valid_audio_out_1
    logic [31:0] prev_val, val_to_display;
    always_ff @(posedge audio_clk) begin
        prev_val <= val_to_display;
    end
    assign val_to_display = btn[1] ? (sw[7] ? valid_audio_out_1 : 16'b0) : prev_val;
    logic [6:0] ss_c;
    assign ss0_c = ss_c; 
    assign ss1_c = ss_c;
    seven_segment_controller mssc(.clk_in(audio_clk),
                                .rst_in(sys_rst),
                                .val_in(val_to_display),
                                .cat_out(ss_c),
                                .an_out({ss0_an, ss1_an}));

  */
  
  // ###### AUDIO TESTING ######

  logic signed [7:0] tone_750; 
  logic signed [7:0] tone_440; 

  sine_generator sine_750 (
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .amp_out(tone_750)
  ); 

  sine_generator sine_440 (
    .clk_in(audio_clk),
    .rst_in(sys_rst),
    .step_in(audio_trigger),
    .amp_out(tone_440)
  ); 

  defparam sine_440.PHASE_INCR = 32'b1001_0110_0010_1111_1100_1001_0110;

  // ############################################################## Set up the sound sources - END 
  
  logic sound_out; 

  pdm my_pdm(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .level_in(tone_440),
    .pdm_out(sound_out)
  );

  assign spkl = sw[0]? sound_out : 0;
  assign spkr = sw[1]? sound_out : 0;

endmodule // top_level


    
    
