# Tang Nano 9K 3D Rendering Demo

Verilog demo to render a 3D transforming cube on the Sipeed Tang Nano 9K FPGA.

This project implements a custom cube rendering module written in Verilog. It calculates and renders a 3D transforming cube directly onto a 1.14" SPI LCD screen. 

<div align="center">
  <video src="demo/fpga_3d_graphics_demo.mov" width="100%" controls autoplay loop></video>
</div>

## Features
* **Parallel Line Rendering:** Evaluates all 12 edges of the 3D cube simultaneously using 12 dedicated hardware circuits.
* **Fixed Point Trigonometry:** 3D rotation using pre calculated Sine/Cosine lookup tables.
* **Dynamic Line Thickness:** Uses Manhattan distance to automatically scale the thickness threshold, keeping lines uniformly thick regardless of their rotation angle.
* **Custom Display Drivers:** Includes a custom SPI Master and LCD controller for controlling the display.

## How It Works

Drawing a 3D object on a 2D screen requires a few specific steps:

1. **The Shape:** The renderer stores the 8 vertices of a standard cube. 
2. **Rotation:** Every frame, the engine looks up Sine and Cosine values from `angle_lut.v` to apply a rotation matrix, rotating those 8 vertices in 3D space.
3. **Projection:** The renderer projects the 3D cube by dropping the z axis depth data, giving standard 2D x and y coordinates.
4. **Drawing the Edges:** As the `lcd_controller.v` scans across the screen pixel by pixel, the renderer checks if the current pixel is close to the imaginary line connecting any of the corners. If it is, the pixel is rendered.

## Project Structure

* **`main.v`:** The main wrapper that wires the pipeline together and maps to the physical FPGA pins.
* **`rgb_lut.v`:** Pre-calculated/scaled RGB values in 565 format used for coloring the background/cube.
* **`cube_renderer.v`:** The core 3D math unit. Handles the transformation operations and line drawing done on the vertices/edges of the cube.
* **`angle_lut.v`:** Pre-calculated/scaled Sine and Cosine values needed for rotation math.
* **`lcd_controller.v`:** Manages screen coordinates and timing signals.
* **`lcd_lut.v`:** Stores initialization commands needed to set up the LCD display.
* **`spi_master.v`:** Sends the pixel data to the LCD through the SPI communication protocol.
* **`tang_nano_9k.cst`:** The physical constraint file mapping the Verilog logic to the Tang Nano's physical pins.

---

## Hardware Used
* **Board:** Sipeed Tang Nano 9K (Gowin GW1NR-9 FPGA)
* **Display:** 1.14" SPI LCD Screen 
* **Toolchain:** Gowin EDA
