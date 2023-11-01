module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    
    input wire [7:0] pmoda, // Tbd how many bits actually needed
    input wire [7:0] pmodb, // Tbd how many bits actually needed
    input wire [3:0] btn,

    output logic spkl, spkr, //speaker outputs
    output logic [15:0] led, // led outputs

    output logic uart_txd, // if we want to use Manta
    input wire uart_rxd

)
    assign led = sw;

endmodule 