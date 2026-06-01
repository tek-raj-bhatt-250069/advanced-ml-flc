# STW7085C — Fuzzy Logic Optimised Controller (FLC)

> **MSc Data Science and Computational Intelligence**  
> Softwarica College of IT and E-commerce (Coventry University)  
> Module: STW7085C — Evolutionary and Fuzzy Systems

---

## Authors

| Name | Student ID | Email |
|---|---|---|
| Sachin Manandhar | 250137 | 250137@softwarica.edu.np |
| Tek Raj Bhatta | 250069 | 250069@softwarica.edu.np |

---

## Overview

This repository contains the MATLAB implementation of a three-part coursework assignment covering the design, optimisation, and benchmarking of a Fuzzy Logic Controller (FLC) for an intelligent assistive living environment.

The system automatically maintains **thermal comfort** and **appropriate lighting** in a smart apartment for a disabled inhabitant, using sensor inputs to drive heating and lighting actuators without user intervention.

---

## Repository Structure

```
advanced-ml-flc/
│
├── fuzzy.m              # Part 1 — Mamdani FLC design and implementation
├── Part2_GA.m           # Part 2 — Genetic Algorithm optimisation of the FLC
├── Part3_CEC.m          # Part 3 — CEC 2005 benchmark (GA vs PSO)
│
└── pictures/
    ├── fig1_temperature_mf.png        # Temperature input MFs
    ├── fig2_lightlevel_mf.png         # Light Level input MFs
    ├── fig3_timeofday_mf.png          # Time of Day input MFs
    ├── fig4_heaterpower_mf.png        # Heater Power output MFs
    ├── fig5_dimmerlevel_mf.png        # Dimmer Level output MFs
    ├── fig6_rule_editor.png           # MATLAB Rule Editor screenshot
    ├── fig7_surface_heater.png        # Control surface — Heater Power
    ├── fig8_surface_dimmer.png        # Control surface — Dimmer Level
    ├── fig9_ruleviewer_cold_evening.png
    ├── fig10_ruleviewer_hot_afternoon.png
    ├── fig11_ruleviewer_cold_night.png
    ├── fig12_ga_convergence.png       # GA convergence curve (100 generations)
    ├── fig13_flc_comparison.png       # Original vs GA-optimised FLC outputs
    ├── fig14_f1_convergence.png       # F1 Sphere convergence — GA vs PSO
    ├── fig15_f6_convergence.png       # F6 Rosenbrock convergence — GA vs PSO
    └── fig16_boxplots.png             # Fitness distribution box plots
```

---

## Part 1 — FLC Design and Implementation (`fuzzy.m`)

### System Description

A Mamdani Type-1 Fuzzy Inference System designed to control heating and lighting in a smart living room.

| Variable | Type | Range | Description |
|---|---|---|---|
| Temperature | Input | 0–40 °C | Ambient room temperature sensor |
| LightLevel | Input | 0–1000 lux | Photosensor for ambient light |
| TimeOfDay | Input | 0–24 hours | Clock input for time-contextual control |
| HeaterPower | Output | 0–100% | Heater/boiler actuation level |
| DimmerLevel | Output | 0–100% | Smart dimmer switch control level |

### Membership Functions

All variables use **triangular membership functions (trimf)** for computational efficiency and interpretability.

| Variable | Number of MFs | Labels |
|---|---|---|
| Temperature | 5 | VeryCold, Cold, Comfortable, Warm, Hot |
| LightLevel | 4 | Dark, Dim, Moderate, Bright |
| TimeOfDay | 5 | Night, Morning, Afternoon, Evening, LateNight |
| HeaterPower | 5 | Off, Low, Medium, High, Maximum |
| DimmerLevel | 5 | Off, Low, Medium, High, Full |

### Inference Configuration

| Component | Method |
|---|---|
| AND operator | Minimum (min) |
| OR operator | Maximum (max) |
| Implication | Minimum (min) — clips output MFs |
| Aggregation | Maximum (max) — combines all rules |
| Defuzzification | Centroid (centre of area) |

### Rule Base (16 rules across 4 groups)

- **Group 1** — Heater rules driven by temperature (5 rules)
- **Group 2** — Dimmer rules driven by light level (4 rules)
- **Group 3** — Time-contextual dimmer rules (3 rules)
- **Group 4** — Combined multi-condition contextual rules (4 rules)

### Scenario Test Results

| Scenario | Temp (°C) | Light (lux) | Time | Heater % | Dimmer % |
|---|---|---|---|---|---|
| Cold dark evening | 8 | 50 | 20:00 | 80.0% | 84.6% |
| Hot bright afternoon | 35 | 900 | 14:00 | 9.5% | 8.8% |
| Comfortable morning | 21 | 400 | 10:00 | 31.7% | 65.5% |
| Very cold dark night | 5 | 20 | 02:00 | 94.4% | 52.6% |
| Warm dim evening | 26 | 200 | 19:00 | 8.8% | 80.0% |

---

## Part 2 — GA Optimisation of the FLC (`Part2_GA.m`)

A **Genetic Algorithm (GA)** automatically tunes all membership function parameters across the FLC's five variables.

### Chromosome Encoding

Each chromosome is a real-valued vector of **72 parameters** (3 params × 24 total MFs):

| Variable | MFs | Params | Chromosome Indices |
|---|---|---|---|
| Temperature (in) | 5 | 15 | 1–15 |
| LightLevel (in) | 4 | 12 | 16–27 |
| TimeOfDay (in) | 5 | 15 | 28–42 |
| HeaterPower (out) | 5 | 15 | 43–57 |
| DimmerLevel (out) | 5 | 15 | 58–72 |

### GA Parameters

| Parameter | Value |
|---|---|
| Population size | 50 chromosomes |
| Generations | 100 |
| Selection | Binary tournament |
| Crossover | Single-point, rate = 0.8 |
| Mutation | Gaussian, rate = 0.1, scale = 0.5 |
| Elitism | Best chromosome preserved each generation |
| Fitness function | RMSE over 200 training samples (σ = 5 noise) |

### Optimisation Results

| Metric | Value |
|---|---|
| Initial RMSE | 4.9504 |
| Optimised RMSE | 4.8267 |
| Improvement | **2.50%** |
| Best generation | Generation 80 |

---

## Part 3 — CEC 2005 Benchmark Comparison (`Part3_CEC.m`)

Empirical comparison of **GA vs PSO** on two CEC 2005 benchmark functions across D = 2 and D = 10 dimensions.

### Benchmark Functions

- **F1 — Shifted Sphere** (unimodal): Tests convergence on smooth, well-behaved landscapes.
- **F6 — Shifted Rosenbrock** (multimodal): Tests robustness on narrow, banana-shaped curved valleys.

### Experimental Setup

- 15 independent runs per experiment
- 10,000 function evaluations per run
- Population/swarm size: 50
- Search bounds: [−100, 100]
- PSO: inertia w = 0.729, coefficients c₁ = c₂ = 1.494 (Clerc–Kennedy)

### Results Summary (Mean ± Std Dev, 15 runs)

| Experiment | D | Mean | Std Dev | Best | Worst |
|---|---|---|---|---|---|
| F1 — GA | 2 | 0.0001 | 0.0001 | 0.0000 | 0.0003 |
| F1 — PSO | 2 | 0.0000 | 0.0000 | 0.0000 | 0.0000 |
| F1 — GA | 10 | 0.2021 | 0.1011 | 0.0637 | 0.4100 |
| F1 — PSO | 10 | 0.0000 | 0.0000 | 0.0000 | 0.0000 |
| F6 — GA | 2 | 13.9432 | 17.6288 | 0.0121 | 64.xx |
| F6 — PSO | 2 | 0.0003 | 0.0012 | 0.0000 | 0.0047 |
| F6 — GA | 10 | 1384.81 | 3507.92 | 40.38 | 12340 |
| F6 — PSO | 10 | 63367.23 | 166509.83 | 0.0718 | 473489 |

### Key Conclusions

- **PSO dominates on unimodal problems (F1)** — efficient gradient-following achieves near-zero error at both dimensionalities.
- **GA is more robust on high-dimensional multimodal problems (F6, D=10)** — crossover maintains diversity and avoids premature convergence.
- **PSO is severely inconsistent on F6 D=10** (std dev 166,509) — particles lose coherence in the narrow curved Rosenbrock valley.
- **GA shows lower variance on F6** (std dev 3,507 vs 166,509), demonstrating greater consistency on complex landscapes.

---

## Requirements

- **MATLAB** R2020a or later
- **Fuzzy Logic Toolbox** (required for Part 1 and Part 2)
- No additional toolboxes required for Part 3

---

## How to Run

### Part 1 — FLC Design
```matlab
% Run in MATLAB
fuzzy
% Opens MATLAB Fuzzy Logic Designer and runs scenario tests
```

### Part 2 — GA Optimisation
```matlab
Part2_GA
% Runs the GA over 100 generations and plots convergence
```

### Part 3 — CEC Benchmark
```matlab
Part3_CEC
% Runs GA and PSO on F1 and F6 for D=2 and D=10
% Outputs results table and convergence plots
```

---

## Report

The full coursework report is available in the repository as `STW7085C_FLC_Report.pdf`.

---

## License

This project was submitted as assessed coursework for STW7085C at Softwarica College of IT and E-commerce (Coventry University). Code is shared for academic reference only.
