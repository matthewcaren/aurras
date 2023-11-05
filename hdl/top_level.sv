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

    //3.072MHz clock to send to i2s
    logic [4:0] i2s_clk_counter;
    logic i2s_clk;
    always_ff @(posedge audio_clk) begin
        i2s_clk_counter <= i2s_clk_counter + 1;
    end
    assign i2s_clk = i2s_clk_counter[4];
    
    // 48kHz clock for word select for i2s
    logic [10:0] lrcl_counter;
    logic lrcl_clk; 
    always_ff @(posedge audio_clk) begin
        lrcl_counter <= lrcl_counter + 1;
    end
    assign lrcl_clk = lrcl_counter[10];

    logic mic_1_data, mic_2_data, mic_3_data;

    // Mic 1: blck - i2s_clk - pmodb[3]; dout - mic_1_data - pmoda[3]; lrcl_clk - pmodb[2], sel - grounded
    // Mic 2: blck - i2s_clk - pmodb[7]; dout - mic_2_data - pmoda[7]; lrcl_clk - pmodb[6], sel - grounded
    // Mic 3: blck - i2s_clk - pmodb[1]; dout - mic_3_data - pmoda[0]; lrcl_clk - pmodb[0], sel - grounded

    assign pmodb[3] = i2s_clk;
    // assign pmodb[7] = i2s_clk;
    // assign pmodb[1] = i2s_clk;

    assign pmodb[2] = lrcl_clk;
    // assign pmodb[6] = lrcl_clk;
    // assign pmodb[0] = lrcl_clk;

    assign mic_1_data = pmoda[3];
    // assign mic_2_data = pmoda[7];
    // assign mic_3_data = pmoda[0];

    // Audio out sends data_valid_out signal at 48kHz
    logic [15:0] audio_out_1, audio_out_2, audio_out_3;
    logic [15:0] valid_audio_out_1, valid_audio_out_2, valid_audio_out_3;
    logic data_valid_out_1, data_valid_out_2, data_valid_out_3;

    i2s mic_1(.mic_data(mic_1_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid_out(data_valid_out_1), .audio_out(audio_out_1));
    // i2s mic_2(.mic_data(mic_2_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid_out(data_valid_out_2), .audio_out(audio_out_2));
    // i2s mic_3(.mic_data(mic_3_data), .i2s_clk(i2s_clk), .lrcl_clk(lrcl_clk), .data_valid_out(data_valid_out_3), .audio_out(audio_out_3));

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

endmodule 