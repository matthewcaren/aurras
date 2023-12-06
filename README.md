# aurras

Active environmental noise cancellation using an FPGA.

<br />

## specs

16-bit audio @ 24 kHz

### clocking

- main clock: 98.3MhZ
- I2S driver clock (main clock / 32) ≈ 3.072 MhZ
- input audio rate from I2S (main clock / 2048) ≈ 48KhZ
- project audio rate (main clock / 4096) ≈ 24kHZ

### memory

- audio buffers are all 1 second, stored in memory as 750 lines of 64 words with 16 bits per word
- 1s convolution requires ~96k bits required working memory for IR + equal-sized convolution buffer

### peripherals

- 3-channel input via I2S MEMS microphones
- 2-channel output to analog amplifier & full-range drivers

## controls

btn0: system reset\
btn1: run SOS analysis\
btn2: monitor audio\
btn3: record impulse\

sw0: channel 0 output enable\
sw1: channel 1 output enable\
sw2: test sine wave output\
sw3: raw input from mic\
sw4: downsampled input from mic\
sw5: one second delayed audio\
sw6: delayed based on {sw 15-10, 00} (8 bit delay)\
sw7: enable impulse recording\

sw9: ssd to convolved audio\
sw10-15: delay amount
