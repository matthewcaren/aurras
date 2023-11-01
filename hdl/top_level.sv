module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    output logic [15:0] led,
    input wire [7:0] pmoda, // Tbd how many bits actually needed
    input wire [2:0] pmodb,
    input wire [3:0] btn,

    output logic spkl, spkr, //speaker outputs

)
    assign led = sw;

endmodule 