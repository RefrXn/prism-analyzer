# PrismAnalyzer
FPGA implementation of a **32×8 WS2812B LED matrix spectrum visualizer**, written in **Verilog-2001**, using the **WM8731 audio codec** for input and a Xilinx FFT IP core for spectral analysis.

---

## 📘 Overview
PrismAnalyzer captures audio from the WM8731 codec via I²S, performs real-time FFT on the audio stream, and maps the frequency bands to a WS2812 LED matrix.  
The system is designed for real-time operation on FPGA hardware and is divided into three primary functional blocks:

- **Codec Subsystem (`top_codec`)** – Handles audio acquisition and codec configuration via I²S and I²C.  
- **FFT Subsystem (`top_fft`)** – Performs frame packing, FFT, magnitude conversion, and band accumulation.  
- **LED Subsystem (`top_led`)** – Converts spectral magnitudes to LED color patterns and drives WS2812 timing.

---

## ⚙️ Module Hierarchy
```text
top.v
├── top_codec.v
│   ├── i2s.v
│   │   ├── timing_gen.v
│   │   └── rx.v
│   └── i2c.v
│       ├── i2c_reg_cfg.v
│       └── i2c_dri.v
│
├── top_fft.v
│   ├── frame_packer.v
│   ├── fft_wrapper.v
│   │   └── xfft_0.xci   (Xilinx FFT IP)
│   ├── complex_to_mag.v
│   ├── band_accum.v
│   └── band_buffer.v
│
└── top_led.v
    ├── spectrum_to_led.v
    └── ws2812_dri.v

