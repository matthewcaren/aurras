# mclk is from the 100 MHz oscillator on Urbana Boad

set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {clk_100mhz}]
create_clock -add -name gclk -period 10.000 -waveform {0 4} [get_ports {clk_100mhz}]

# Set Bank 0 voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# USER GREEN LEDS
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33} [ get_ports {led[0]} ]
set_property -dict {PACKAGE_PIN C14  IOSTANDARD LVCMOS33} [ get_ports {led[1]} ]
set_property -dict {PACKAGE_PIN D14  IOSTANDARD LVCMOS33} [ get_ports {led[2]} ]
set_property -dict {PACKAGE_PIN D15  IOSTANDARD LVCMOS33} [ get_ports {led[3]} ]
set_property -dict {PACKAGE_PIN D16  IOSTANDARD LVCMOS33} [ get_ports {led[4]} ]
set_property -dict {PACKAGE_PIN F18  IOSTANDARD LVCMOS33} [ get_ports {led[5]} ]
set_property -dict {PACKAGE_PIN E17  IOSTANDARD LVCMOS33} [ get_ports {led[6]} ]
set_property -dict {PACKAGE_PIN D17  IOSTANDARD LVCMOS33} [ get_ports {led[7]} ]
set_property -dict {PACKAGE_PIN C17  IOSTANDARD LVCMOS33} [ get_ports {led[8]} ]
set_property -dict {PACKAGE_PIN B18  IOSTANDARD LVCMOS33} [ get_ports {led[9]} ]
set_property -dict {PACKAGE_PIN A17  IOSTANDARD LVCMOS33} [ get_ports {led[10]} ]
set_property -dict {PACKAGE_PIN B17  IOSTANDARD LVCMOS33} [ get_ports {led[11]} ]
set_property -dict {PACKAGE_PIN C18  IOSTANDARD LVCMOS33} [ get_ports {led[12]} ]
set_property -dict {PACKAGE_PIN D18  IOSTANDARD LVCMOS33} [ get_ports {led[13]} ]
set_property -dict {PACKAGE_PIN E18  IOSTANDARD LVCMOS33} [ get_ports {led[14]} ]
set_property -dict {PACKAGE_PIN G17  IOSTANDARD LVCMOS33} [ get_ports {led[15]} ]

set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {rgb1[0]}];
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {rgb1[1]}];
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {rgb1[2]}];
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {rgb0[0]}];
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports {rgb0[1]}];
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {rgb0[2]}];

## USER PUSH BUTTON
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33} [ get_ports "btn[0]" ]
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [ get_ports "btn[1]" ]
set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33} [ get_ports "btn[2]" ]
set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33} [ get_ports "btn[3]" ]

## USER SLIDE SWITCH
set_property -dict {PACKAGE_PIN G1  IOSTANDARD LVCMOS33} [ get_ports "sw[0]" ]
set_property -dict {PACKAGE_PIN F2  IOSTANDARD LVCMOS33} [ get_ports "sw[1]" ]
set_property -dict {PACKAGE_PIN F1  IOSTANDARD LVCMOS33} [ get_ports "sw[2]" ]
set_property -dict {PACKAGE_PIN E2  IOSTANDARD LVCMOS33} [ get_ports "sw[3]" ]
set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [ get_ports "sw[4]" ]
set_property -dict {PACKAGE_PIN D2  IOSTANDARD LVCMOS33} [ get_ports "sw[5]" ]
set_property -dict {PACKAGE_PIN D1  IOSTANDARD LVCMOS33} [ get_ports "sw[6]" ]
set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [ get_ports "sw[7]" ]
set_property -dict {PACKAGE_PIN B2  IOSTANDARD LVCMOS33} [ get_ports "sw[8]" ]
set_property -dict {PACKAGE_PIN A4  IOSTANDARD LVCMOS33} [ get_ports "sw[9]" ]
set_property -dict {PACKAGE_PIN A5  IOSTANDARD LVCMOS33} [ get_ports "sw[10]" ]
set_property -dict {PACKAGE_PIN A6  IOSTANDARD LVCMOS33} [ get_ports "sw[11]" ]
set_property -dict {PACKAGE_PIN C7  IOSTANDARD LVCMOS33} [ get_ports "sw[12]" ]
set_property -dict {PACKAGE_PIN A7  IOSTANDARD LVCMOS33} [ get_ports "sw[13]" ]
set_property -dict {PACKAGE_PIN B7  IOSTANDARD LVCMOS33} [ get_ports "sw[14]" ]
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [ get_ports "sw[15]" ]

# USER SEVEN SEGMENT DISPLAY HIGH SIDE DRIVE ACTIVE LOW
set_property -dict {PACKAGE_PIN B3  IOSTANDARD LVCMOS33} [ get_ports "ss0_an[0]"]
set_property -dict {PACKAGE_PIN C3  IOSTANDARD LVCMOS33} [ get_ports "ss0_an[1]"]
set_property -dict {PACKAGE_PIN H6  IOSTANDARD LVCMOS33} [ get_ports "ss0_an[2]"]
set_property -dict {PACKAGE_PIN G6  IOSTANDARD LVCMOS33} [ get_ports "ss0_an[3]"]

set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [ get_ports "ss1_an[0]"]
set_property -dict {PACKAGE_PIN F5  IOSTANDARD LVCMOS33} [ get_ports "ss1_an[1]"]
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [ get_ports "ss1_an[2]"]
set_property -dict {PACKAGE_PIN E4  IOSTANDARD LVCMOS33} [ get_ports "ss1_an[3]"]

# USER SEVEN SEGMENT DISPLAY LOW SIDE DRIVE ACTIVE LOW
set_property -dict {PACKAGE_PIN E6  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[0]"]
set_property -dict {PACKAGE_PIN B4  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[1]"]
set_property -dict {PACKAGE_PIN D5  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[2]"]
set_property -dict {PACKAGE_PIN C5  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[3]"]
set_property -dict {PACKAGE_PIN D7  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[4]"]
set_property -dict {PACKAGE_PIN D6  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[5]"]
set_property -dict {PACKAGE_PIN C4  IOSTANDARD LVCMOS33} [ get_ports "ss0_c[6]"]
#set_property -dict {PACKAGE_PIN B5  IOSTANDARD LVCMOS33} [ get_ports "ss0_cdp"]

set_property -dict {PACKAGE_PIN F3  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[0]"]
set_property -dict {PACKAGE_PIN G5  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[1]"]
set_property -dict {PACKAGE_PIN J3  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[2]"]
set_property -dict {PACKAGE_PIN H4  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[3]"]
set_property -dict {PACKAGE_PIN F4  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[4]"]
set_property -dict {PACKAGE_PIN H3  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[5]"]
set_property -dict {PACKAGE_PIN E5  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[6]"]
#set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [ get_ports "ss1_c[7]"]

set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[0]" ]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[1]" ]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[2]" ]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[3]" ]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[4]" ]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[5]" ]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[6]" ]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33}  [ get_ports "pmoda[7]" ]

set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[0]" ]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[1]" ]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[2]" ]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33}  [ get_ports "pmodbclk" ]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33}  [ get_ports "pmodblock" ]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[3]" ]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[4]" ]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[5]" ]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[6]" ]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33}  [ get_ports "pmodb[7]" ]

# HDMI Signals
set_property -dict { PACKAGE_PIN V17   IOSTANDARD TMDS_33  } [get_ports {hdmi_clk_n}]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD TMDS_33  } [get_ports {hdmi_clk_p}]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_n[0]}]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_n[1]}]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_n[2]}]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_p[0]}]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_p[1]}]
set_property -dict { PACKAGE_PIN R14   IOSTANDARD TMDS_33  } [get_ports {hdmi_tx_p[2]}]

# change G15 to B13 and E13 to B14
set_property PACKAGE_PIN B13 [ get_ports "spkl"]
set_property PACKAGE_PIN B14 [ get_ports "spkr"]
set_property IOSTANDARD LVCMOS33 [ get_ports "spk*"]

set_property PACKAGE_PIN E12 [ get_ports "mic_clk"]
set_property PACKAGE_PIN D12 [ get_ports "mic_data"]
set_property IOSTANDARD LVCMOS33 [ get_ports "mic*"]

# change G15 to B13 and E13 to B14
set_property PACKAGE_PIN B13 [ get_ports "spkl"]
set_property PACKAGE_PIN B14 [ get_ports "spkr"]
set_property IOSTANDARD LVCMOS33 [ get_ports "spk*"]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# uart pins for working with manta:
set_property PACKAGE_PIN B16 [ get_ports "uart_rxd"]
set_property PACKAGE_PIN A16 [ get_ports "uart_txd"]
set_property IOSTANDARD LVCMOS33 [ get_ports "uart*"]