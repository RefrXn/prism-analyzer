[![FPGA](https://img.shields.io/badge/FPGA-Verilog--2001-green.svg)]()
[![Status](https://img.shields.io/badge/status-active-success.svg)]()

# PrismAnalyzer
FPGA implementation of a **32×8 WS2812B LED matrix spectrum visualizer**, in **Verilog-2001**, using the **WM8731 audio codec** for input and a Xilinx FFT IP core for spectral analysis.

---

> 如果你想知道 spectrum_to_led.v 的技术细节，欢迎联系我。如果你想要使用二维数组处理，很可能需要写SystemVerilog，但是有其他的解决办法。
> 因为ws2812规格不一，所以此处不做赘述。

>已知问题：
>1. 由于FFT频谱泄露，导致的底噪较大。如需解决，建议加窗。
>2. 目前没有自动增益调整，如果需要调整增益，可以在 top.v 的末端进行移位。
>3. 目前（黑金AN831上自带的晶振源）主时钟12.288MHz，可能与其他wm8731板卡不同。
>4. 使用3.3v的输出也可以驱动ws2812，不过建议把ws2812电源电压调小一些，本人使用4.7v左右。

---

## Overview
PrismAnalyzer captures audio from the WM8731 codec via I²S, performs real-time FFT on the audio stream, and maps the frequency bands to a WS2812 LED matrix.  
The system is designed for real-time operation on FPGA hardware and is divided into three primary functional blocks:

- **Codec Subsystem (`top_codec`)** – Handles audio acquisition and codec configuration via I²S and I²C.  
- **FFT Subsystem (`top_fft`)** – Performs frame packing, FFT, magnitude conversion, and band accumulation.  
- **LED Subsystem (`top_led`)** – Converts spectral magnitudes to LED color patterns and drives WS2812 timing.

---

## Module Hierarchy
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
```

---

## Data Flow
```text
Audio In (WM8731 / I²S)
        ↓
     top_codec
        ↓
     top_fft
        ↓
  FFT → Magnitude → Band Accumulation
        ↓
     top_led
        ↓
 Spectrum Mapping → WS2812 Timing
        ↓
 LED Matrix Visualization
```

---

## Notes / Disclaimer

- ***请不要上传到 CSDN***

- The **`spectrum_to_led`** module is **not provided** in this repository because WS2812B matrix wiring orders differ across setups.  
  Please implement your own mapping logic. For a two-dimensional matrix in **Verilog-2001**, consider flattening it into a 1-D bus (row- or column-major) and using `generate` blocks or index arithmetic to map `(row, col)` → `flat_index`.

- **Please do not upload this project to CSDN or any other content-reposting sites.**

- The **WM8731 codec driver** section is **based on Alinx teaching examples**.  
  Portions of the **WS2812 driver** code originate from unknown open-source sources.  
  If any copyright infringement is involved, please contact me for removal.

- **Hardware used:**  
  - **FPGA Board:** Alinx ATRIX7035  
  - **Codec Module:** Alinx AN831 (WM8731)  
  - **Microphone:** Primo EM272Z1

---

本项目为 **南京邮电大学「芯芯点灯」活动参赛作品**  




