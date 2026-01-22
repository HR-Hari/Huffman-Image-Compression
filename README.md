# Huffman Image Compression

This repository provides **lossless Huffman image compression** implemented in both **Python** and **MATLAB/Octave**. It demonstrates image compression, reconstruction, and performance evaluation.

## Features

* **Huffman Coding:** Efficient algorithm for lossless image compression.
* **Python GUI:** Interactive interface for compressing and decompressing images.
* **MATLAB/Octave:** Manual pipeline including entropy analysis and PSNR calculation.
* **Benchmarking:** Comparison with inbuilt Huffman functions.

---

## Getting Started

### 🐍 Python

To use the Python GUI version:

1.  **Install dependencies:**
    ```bash
    pip install -r python/requirements.txt
    ```

2.  **Run the application:**
    ```bash
    python python/src/huffman_image_compressor.py
    ```

3.  **Usage:**
    * Select and compress images (`.png`, `.jpg`, `.bmp`).
    * Save and decompress `.huff` files.
    * View the **Compression Ratio** displayed directly in the GUI.

### 🔢 MATLAB / Octave

To use the MATLAB or Octave scripts:

1.  Open `matlab/src/Huffman_Image_Compression.m`.
2.  Run the script to:
    * Compress grayscale images.
    * Reconstruct the original images.
    * Calculate Entropy, MSE, PSNR, and Compression Ratio.

---

## Metrics

The project evaluates performance using the following metrics:

| Metric | Description |
| :--- | :--- |
| **Entropy** | Measures the average information content of the image. |
| **Compression Ratio** | The ratio of bits in the original image vs. the compressed image. |
| **PSNR & MSE** | **Peak Signal-to-Noise Ratio** and **Mean Squared Error** are used to verify reconstruction quality. |
