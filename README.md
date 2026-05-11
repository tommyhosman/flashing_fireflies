# Fireflies: Ghostty Shader

An immersive, mathematically driven custom background shader for the [Ghostty](https://ghostty.org/) terminal. 

This shader simulates the spontaneous synchronization of fireflies using a Kuramoto-style pulse-coupled oscillator model. Instead of random blinking, the fireflies influence each other, building from chaotic, entropic blinking into brief, beautiful moments of complete unison.

[demo.webm](https://github.com/user-attachments/assets/6ad879ab-37ee-4cf5-90c8-0e2e17c98c40)


## Features (configurable)
* **Mathematical Synchronization:** Built on bounded phase-offsets to simulate natural biological rhythms.
* **Organic Clustering:** Uses 2D Value Noise to create dense swarms and empty voids, avoiding artificial grid layouts.
* **Depth & Parallax:** Simulates a 3D Z-axis, with fireflies drifting closer to the screen with dynamic scaling and brightness.
* **Lens Dispersion:** Subtle chromatic aberration toward the edges of the terminal window.
* **Cinematic Climax:** A configurable color shift that pushes the swarm into a blinding gold during perfect synchronization.

## Installation

1. Save the `fireflies.glsl` file to your machine (e.g., `~/.config/ghostty/shaders/fireflies.glsl`).
2. Open your Ghostty configuration file (`~/.config/ghostty/config`).
3. Add the following lines:

```ini
# Path to the shader
custom-shader = /path/to/your/fireflies.glsl
```

### Optional: Keep the animation running when the terminal loses focus
`custom-shader-animation = always`


#### Disclaimer: all code was written by an LLM.