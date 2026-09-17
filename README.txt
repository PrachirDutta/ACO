ZedBoard SSSC POD FPGA-in-the-Loop files
=======================================

Files
-----
1. sssc_pod_controller.v
   Synthesizable Verilog POD controller for AMD ZedBoard.

2. prepare_FPGA_POD_coefficients.m
   Loads optimized_POD_parameters.mat, performs Tustin discretization,
   converts coefficients to signed Q16.16 and saves FPGA_POD_coefficients.mat.

3. load_FPGA_POD_coefficients.m
   Loads the FPGA-ready coefficients into the MATLAB workspace.

4. double_to_q16.m
   Converts DW1/DW2 from MATLAB numeric values to signed Q16.16 int32.

5. q16_to_double.m
   Converts the FPGA Vq_ref output from Q16.16 back to MATLAB double.

6. fil_test_sssc_pod.m
   Basic MATLAB HDL Verifier FIL test. The generated FIL class name and
   input order must be checked after running filWizard.

7. matlab_reference_pod.m
   Floating-point reference implementation of the exact POD difference
   equations, useful for verification against FPGA output.

Required workflow
-----------------
A. Put optimized_POD_parameters.mat in the same MATLAB folder.
B. Edit Ts in prepare_FPGA_POD_coefficients.m to your exact controller
   sample time.
C. Run:
       prepare_FPGA_POD_coefficients
D. Open MATLAB and run:
       filWizard
E. Select ZedBoard and Simulink or MATLAB FIL workflow.
F. Add sssc_pod_controller.v and choose sssc_pod_controller as the DUT.
G. Identify clk as the DUT clock and rst as reset.
H. Generate the FIL block/System object.
I. In Simulink:
   - Convert DW1 and DW2 to Q16.16 before the FIL block.
   - Feed Aw_Q...K_Q as constant FIL inputs.
   - Feed sample_valid = 1 for each new controller sample.
   - Convert vq_ref from Q16.16 to double after the FIL block.
   - Feed the resulting Vq_ref to the SSSC.

Important
---------
The exact argument order of a generated MATLAB FIL System object is
determined by HDL Verifier. Check the generated class/help output before
using fil_test_sssc_pod.m.

Do not discretize Vq_ref after the FPGA. Only convert from Q16.16:
    Vq_ref = double(vq_ref_q) / 65536
