`timescale 1ns / 1ps
`default_nettype none

module convolve_line(input wire [1023:0] ir_line,
                     input wire [1023:0] audio_line,
                     output logic [47:0] convolved_line);

    logic signed [63:0] [31:0] intermediate_products;
    logic signed [47:0] build_up_sum;

    genvar i;
    generate
    for (i = 0; i < 64; i=i+1) begin
        always_comb begin
            intermediate_products[i] = ir_line[((i << 4) + 15) : (i << 4)] * audio_line[(((63-i) << 4) + 15) : ((63-i) << 4)];
        end
    end
    endgenerate

    genvar j;
    generate
    for (j = 0; j < 64; j=j+1) begin
        always_comb begin
            build_up_sum = build_up_sum + intermediate_products[j];
        end
    end
    endgenerate
endmodule

`timescale 1ns / 1ps
`default_nettype wire