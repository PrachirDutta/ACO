# ACO-Based SSSC Power Oscillation Damping Controller

This repository contains a MATLAB/Simulink implementation for optimizing and implementing a **Power Oscillation Damping (POD) controller** for a **Static Synchronous Series Compensator (SSSC)**.

The project combines:

- **Ant Colony Optimization for Continuous Domains (ACOR)** for POD parameter tuning
- A **Particle Swarm Optimization (PSO)** implementation for comparison/alternative optimization
- MATLAB/Simulink-based power-system simulation
- Continuous-to-discrete POD controller conversion using the **Tustin (bilinear) transformation**
- Fixed-point **Q16.16** conversion for FPGA implementation
- A synthesizable **Verilog POD controller**
- **FPGA-in-the-Loop (FIL)** verification using an AMD/Xilinx ZedBoard

The overall objective is to tune the POD controller parameters so that oscillations in the simulated power system are minimized and then deploy the optimized controller to FPGA hardware.

---

## Project Overview

Power-system disturbances can introduce electromechanical oscillations that reduce system stability. In this project, an SSSC-based POD controller is used to improve damping.

The optimization process searches for suitable controller parameters such as:

- Controller gain `K`
- Washout time constant `Tw`
- Lead-lag time constants `T1`, `T2`, `T3`, and `T4`

The candidate parameters are evaluated through the Simulink model. The fitness function uses the simulated speed-deviation signals `DW1` and `DW2` and minimizes their final absolute values.

Conceptually:

```text
Controller Parameters
        |
        v
Optimization Algorithm
   (ACOR / PSO)
        |
        v
MATLAB Fitness Function
        |
        v
SSSC_PODcontrol.slx
        |
        v
DW1 / DW2 Oscillation Response
        |
        v
Fitness = |DW1(end)| + |DW2(end)|
```

After optimization, the selected continuous-time controller parameters can be discretized and converted to fixed-point coefficients for FPGA implementation.

---

## Repository Structure

| File | Description |
| --- | --- |
| `ACOMain.m` | Main ACOR/continuous Ant Colony Optimization routine for tuning POD controller parameters. |
| `Main.m` | Particle Swarm Optimization implementation used for POD parameter optimization. |
| `fitnessfunc.m` | Evaluates candidate controller parameters by running the `SSSC_PODcontrol` Simulink model. |
| `RouletteWheelSelection.m` | Roulette-wheel selection function used by the ACOR algorithm. |
| `SSSC_PODcontrol.slx` | Main Simulink model containing the SSSC and POD control system. |
| `SimplifiedPowerPlantGeneratorToTransmissionGrid.slx` | Power-system / generator-to-grid simulation model. |
| `optimized_POD_parameters.mat` | Stores optimized POD controller parameters. |
| `Discretisedvalues.m` | Converts optimized continuous POD parameters to discrete coefficients using Tustin discretization. |
| `prepare_FPGA_POD_coefficients.m` | Prepares and converts controller coefficients to signed Q16.16 representation for FPGA use. |
| `FPGA_POD_coefficients.mat` | FPGA-ready POD coefficients. |
| `load_FPGA_POD_coefficients.m` | Loads FPGA-ready coefficients into the MATLAB workspace. |
| `double_to_q16.m` | Converts MATLAB floating-point values to signed Q16.16 integers. |
| `q16_to_double.m` | Converts signed Q16.16 FPGA outputs back to MATLAB `double`. |
| `sssc_pod_controller.v` | Synthesizable Verilog implementation of the POD controller. |
| `matlab_reference_pod.m` | Floating-point MATLAB reference model for validating the FPGA controller equations. |
| `fil_test_sssc_pod.m` | MATLAB HDL Verifier FPGA-in-the-Loop test script. |

---

## Optimization Algorithms

### Ant Colony Optimization for Continuous Domains

`ACOMain.m` implements an **ACOR-style optimization algorithm**.

The algorithm maintains an archive of candidate solutions. New ants are generated using Gaussian probability distributions around selected archive solutions. Candidate solutions are evaluated using the Simulink-based fitness function, merged with the existing archive, sorted by fitness, and the best solutions are retained.

Important ACOR parameters include:

```matlab
nPop    = 50;   % Archive size
nSample = 50;   % New ants per iteration
q       = 0.5;  % Intensification parameter
zeta    = 1.0;  % Deviation-distance ratio
```

The optimization result is stored in:

```text
optimized_POD_parameters.mat
```

---

### Particle Swarm Optimization

`Main.m` contains a PSO implementation for optimizing the controller parameters.

Each particle represents a possible set of POD parameters. Particle positions are updated according to:

- Particle velocity
- Personal best solution
- Global best solution

The implementation uses constriction-factor PSO coefficients and evaluates every candidate through `fitnessfunc.m`.

This provides an alternative optimization approach and can also be used for comparing optimization performance.

---

## Fitness Function

The optimization algorithms call:

```matlab
fitnessfunc(x)
```

The candidate parameter vector is assigned to controller variables and the Simulink model is executed:

```matlab
sim('SSSC_PODcontrol');
```

The optimization objective is calculated from the simulated rotor/speed-deviation signals:

```matlab
Dw1 = abs(DW1);
Dw2 = abs(DW2);

W = Dw1(end) + Dw2(end);
```

Therefore, the optimizer attempts to minimize the remaining oscillation magnitude at the end of the simulation.

---

## POD Controller Workflow

The intended workflow is:

```text
Power-System Model
       |
       v
Measure DW1 / DW2
       |
       v
POD Controller
       |
       v
Generate Vq_ref
       |
       v
SSSC
       |
       v
Improve Oscillation Damping
```

During optimization:

```text
ACOR / PSO
    |
    v
Select POD Parameters
    |
    v
Run Simulink Model
    |
    v
Calculate Fitness
    |
    v
Update Population
    |
    v
Best POD Parameters
```

---

## Requirements

The project is intended for use with MATLAB and Simulink.

For the complete FPGA-in-the-Loop workflow, the environment should include the MathWorks HDL/FIL tools and hardware support required for the target **AMD/Xilinx ZedBoard**.

Typical components include:

- MATLAB
- Simulink
- HDL Verifier for FPGA-in-the-Loop operation
- Compatible AMD/Xilinx FPGA tools
- ZedBoard hardware for FIL testing

The exact MATLAB release and FPGA tool versions should be selected according to the HDL Verifier / ZedBoard compatibility requirements of your environment.

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/PrachirDutta/ACO.git
cd ACO
```

Open the repository folder in MATLAB.

---

### 2. Open the Simulink model

Open:

```text
SSSC_PODcontrol.slx
```

Verify that the model runs correctly before starting an optimization.

---

### 3. Run the ACOR optimization

In MATLAB:

```matlab
ACOMain
```

The script evaluates candidate POD parameters using the Simulink model and reports the best fitness value.

The optimized controller parameters are saved to:

```text
optimized_POD_parameters.mat
```

---

### 4. Alternative: Run PSO

To use the Particle Swarm Optimization implementation:

```matlab
Main
```

The PSO routine also evaluates parameter sets through `fitnessfunc.m`.

---

## Continuous-to-Discrete Conversion

The FPGA controller operates digitally, so the optimized continuous controller must be converted into discrete-time equations.

`Discretisedvalues.m` uses the **Tustin transformation**:

```text
        2   1 - z^-1
s =    ---  ---------
        Ts  1 + z^-1
```

The controller sample time is defined in the script, for example:

```matlab
Ts = 0.001;
```

> **Important:** `Ts` must match the actual sample interval at which the FPGA POD controller receives new `DW1` / `DW2` samples.

---

## FPGA Coefficient Preparation

Once `optimized_POD_parameters.mat` has been generated, prepare the FPGA coefficients using:

```matlab
prepare_FPGA_POD_coefficients
```

This process:

1. Loads the optimized continuous-time POD parameters.
2. Performs Tustin discretization.
3. Generates the discrete controller coefficients.
4. Converts the coefficients to signed **Q16.16 fixed-point** format.
5. Saves them to:

```text
FPGA_POD_coefficients.mat
```

To load the FPGA-ready parameters:

```matlab
load_FPGA_POD_coefficients
```

---

## Q16.16 Fixed-Point Representation

The FPGA implementation uses signed Q16.16 fixed-point values.

MATLAB input values can be converted using:

```matlab
double_to_q16(...)
```

FPGA outputs can be converted back to floating point using:

```matlab
q16_to_double(...)
```

The equivalent conversion from a Q16.16 FPGA output is:

```matlab
Vq_ref = double(vq_ref_q) / 65536;
```

Do **not** discretize `Vq_ref` again after the FPGA. It only needs to be converted from fixed-point representation back to MATLAB floating-point form.

---

## FPGA-in-the-Loop Workflow

The repository includes a synthesizable Verilog implementation:

```text
sssc_pod_controller.v
```

A typical ZedBoard FIL workflow is:

1. Generate optimized POD parameters.
2. Set the correct controller sample time.
3. Run:

```matlab
prepare_FPGA_POD_coefficients
```

4. Start the MATLAB FIL Wizard:

```matlab
filWizard
```

5. Select the **ZedBoard** target.
6. Add:

```text
sssc_pod_controller.v
```

7. Select `sssc_pod_controller` as the DUT.
8. Configure:
   - `clk` as the DUT clock
   - `rst` as reset
9. Generate the FIL block or MATLAB System object.
10. Connect the generated FPGA interface to the Simulink model.

---

## Simulink FIL Signal Flow

Before the FIL block:

```text
DW1 ----> double_to_q16 ----\
                             >---- FPGA POD Controller
DW2 ----> double_to_q16 ----/
```

The discrete POD coefficients should be supplied to the FPGA controller as constant inputs.

For every new controller sample:

```text
sample_valid = 1
```

After the FIL block:

```text
FPGA vq_ref
    |
    v
q16_to_double
    |
    v
Vq_ref
    |
    v
SSSC
```

---

## FPGA Verification

`matlab_reference_pod.m` contains a floating-point reference implementation of the POD difference equations.

It can be used to compare:

```text
MATLAB Reference Output
          vs.
FPGA Controller Output
```

This helps verify that:

- Tustin discretization is correct
- Fixed-point coefficient conversion is correct
- Verilog arithmetic matches the intended controller equations
- FPGA output is consistent with the MATLAB implementation

`fil_test_sssc_pod.m` provides a basic MATLAB HDL Verifier FIL test.

> The exact argument order of the generated FIL System object depends on HDL Verifier. Always check the generated class or help output before using the FIL test script.

---

## Typical End-to-End Workflow

```text
1. Run and validate the Simulink power-system model
                    |
                    v
2. Optimize POD parameters using ACOR or PSO
                    |
                    v
3. Save optimized_POD_parameters.mat
                    |
                    v
4. Select the FPGA controller sample time
                    |
                    v
5. Apply Tustin discretization
                    |
                    v
6. Convert coefficients to Q16.16
                    |
                    v
7. Generate FPGA_POD_coefficients.mat
                    |
                    v
8. Synthesize sssc_pod_controller.v
                    |
                    v
9. Create ZedBoard FPGA-in-the-Loop interface
                    |
                    v
10. Compare MATLAB and FPGA controller outputs
                    |
                    v
11. Connect FPGA-generated Vq_ref to the SSSC model
```

---

## Key Technologies

- MATLAB
- Simulink
- Ant Colony Optimization / ACOR
- Particle Swarm Optimization
- Power Oscillation Damping
- Static Synchronous Series Compensator
- Tustin Discretization
- Fixed-Point Q16.16 Arithmetic
- Verilog HDL
- FPGA-in-the-Loop
- AMD/Xilinx ZedBoard

---

## Future Improvements

Possible extensions to the project include:

- Increasing optimization iterations and performing convergence studies
- Comparing ACOR and PSO using identical simulation conditions
- Adding Integral of Time-weighted Absolute Error (ITAE) or other damping-performance objectives
- Testing multiple operating points and disturbances
- Automating FPGA coefficient generation after optimization
- Adding plots comparing MATLAB and FPGA POD outputs
- Adding hardware resource and timing reports
- Adding automated regression tests for fixed-point calculations
- Improving documentation of the Simulink model and controller architecture

---

## Repository

GitHub:

https://github.com/PrachirDutta/ACO

---

## Author

**Prachir Dutta**

GitHub: [@PrachirDutta](https://github.com/PrachirDutta)

---

## Notes

This repository is primarily intended for research, simulation, controller optimization, and FPGA validation of an SSSC-based Power Oscillation Damping controller.

Before using the FPGA workflow, verify the controller sampling time, generated fixed-point coefficients, FPGA interface signal order, and MATLAB/FPGA numerical agreement for your specific hardware and software configuration.
