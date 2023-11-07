module i2s(
    input wire mic_data,
    input wire audio_clk,
    input wire rst_in,

    // Outputs to mic
    output logic i2s_clk,
    output logic lrcl_clk,

    // Deserialized outputs to system
    output logic data_valid_out,
    output logic [15:0] audio_out
);

logic [5:0] current_address;
logic prev_lrcl_clk;
logic [63:0] build_up_audio;

// 3.072MHz clock to send to i2s
logic [4:0] i2s_clk_counter;
logic i2s_clk;
assign i2s_clk = i2s_clk_counter[4];
    
// 48kHz clock for word select for i2s
logic [10:0] lrcl_counter;
logic lrcl_clk; 
assign lrcl_clk = (lrcl_counter > 31) && (lrcl_counter < 1057);

always_ff @(posedge audio_clk) begin
    if (rst_in) begin
        lrcl_counter <= 0;
        i2s_clk_counter <= 0;
        build_up_audio <= 0;
    end
    i2s_clk_counter <= i2s_clk_counter + 1;
    lrcl_counter <= lrcl_counter + 1;

    if (~(prev_lrcl_clk) && lrcl_clk) begin
        audio_out <= build_up_audio[30:13];
        data_valid_out <= 1;
        build_up_audio <= mic_data;
        current_address <= 1;
    end else begin
        current_address <= current_address + 1;
        build_up_audio <= {build_up_audio[62:0], mic_data};
    end
    if (data_valid_out) begin
        data_valid_out <= 0;
        audio_out <= 0;
    end
    prev_lrcl_clk <= lrcl_clk;
    end
endmodule