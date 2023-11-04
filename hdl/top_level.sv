module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    input wire [7:0] pmoda, // Tbd how many bits actually needed
    input wire [7:0] pmodb, // Tbd how many bits actually needed
    input wire [3:0] btn,
    output logic [6:0] ss0_c,
    output logic [6:0] ss1_c,
    output logic [3:0] ss0_an,
    output logic [3:0] ss1_an,
    output logic spkl,
    output logic spkr, //speaker outputs
    output logic [15:0] led, // led outputs
    output logic uart_txd, // if we want to use Manta
    input wire uart_rxd
);

    assign led = sw;

    logic audio_clk;
    logic audio_trigger;

    audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(audio_clk)); //98.3MHz
    // we make 98.3 MHz since that number is cleanly divisible by
    // 32 to give us 3.072 MHz.  3.072 MHz is nice because it is cleanly divisible
    // by nice powers of 2 to give us reasonable audio sample rates. For example,
    // a decimation by a factor of 64 could give us 6 bit 48 kHz audio
    // a decimation by a factor of 256 gives us 8 bit 12 kHz audio
    //we do the latter in this lab.

    logic [11:0] counter;
    always_ff @(posedge audio_clk) begin
        counter <= counter + 1;
    end

    assign audio_trigger = (counter == 0);

    logic [4:0] i2s_clk_counter;
    logic i2s_clk;
    always_ff @(posedge audio_clk) begin
        i2s_clk_counter <= i2s_clk_counter + 1;
    end
    assign i2s_clk = (i2s_clk_counter > 15);
    
    logic [10:0] lrcl_counter;
    logic lrcl_clk;
    always_ff @(posedge audio_clk) begin
        lrcl_counter <= lrcl_counter + 1;
    end
    assign lrcl_clk = (lrcl_counter > 1027);

    logic mic_1_data;
    logic mic_2_data;
    logic mic_3_data;

    // Mic 1: blck - i2s_clk - pmodb[3], dout - pmodb[2], lrcl - pmodb[1], sel - grounded
    // Mic 2: blck - i2s_clk - pmodb[7], dout - pmodb[6], lrcl - pmodb[5], sel - grounded
    // Mic 3: blck - i2s_clk - pmoda[3], dout - pmoda[2], lrcl - pmoda[1], sel - grounded

    assign pmodb[3] = i2s_clk;
    // assign pmodb[7] = i2s_clk;
    // assign pmoda[3] = i2s_clk;

    assign pmodb[1] = lrcl_clk;
    // assign pmodb[5] = lrcl_clk;
    // assign pmoda[1] = lrcl_clk;

    assign mic_1_data = pmodb[2];
    // assign mic_2_data = pmodb[6];
    // assign mic_3_data = pmoda[2];

    logic [63:0] actual_audio_out;
    logic [63:0] audio_out;
    logic data_valid;
    i2s mic_1(.mic_data(mic_1_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid(data_valid), .data_out(audio_out));

    always_ff @(posedge audio_clk) begin
        if (data_valid) begin
            actual_audio_out <= audio_out;
        end
    end 
    // i2s mic_2(.mic_data(mic_2_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid(), .full_audio());
    // i2s mic_3(.mic_data(mic_3_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid(), .full_audio());

    // logic [1:0] mic_select;
    // assign mic_select = sw[15:14]
    // always_comb begin
    //     case (mic_select)
    //         2'b10: // Select mic 1
    //         2'b11: // Select mic 2
    //         2'b00: // Select mic 3
    //         default: 
    //     endcase
        
    // end
    
    logic [6:0] ss_c;
    assign ss0_c = ss_c; //control upper four digit's cathodes!
    assign ss1_c = ss_c; //same as above but for lower four digits!

    logic [31:0] val_to_display;
    assign val_to_display = sw[7] ? actual_audio_out[63:32] : (sw[8] ? actual_audio_out[31:0] : 32'b0);
    seven_segment_controller mssc(.clk_in(audio_clk),
                                .rst_in(sys_rst),
                                .val_in(val_to_display),
                                .cat_out(ss_c),
                                .an_out({ss0_an, ss1_an}));


endmodule 