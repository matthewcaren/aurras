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

- 2s impulse response = 96 kB → ~192 kB required working memory for IR + convolution buffer
- delay buffer @ 0.5 meters ≈ 560 bits

### peripherals

- 3-channel input via I2S MEMS microphones
- 2-channel output to analog amplifier & full-range drivers

## controls

btn0: system reset\
btn1: run SOS analysis

sw0: channel 0 output enable\
sw1: channel 1 output enable\
sw2: test sine wave output\
sw3: raw input from mic\
sw4: downsampled input from mic\
sw5: SOS output enable\
sw6: output delayed mic stream
