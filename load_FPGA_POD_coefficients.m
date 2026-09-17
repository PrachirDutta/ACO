%=======================================================================
% LOAD FPGA-READY POD COEFFICIENTS INTO MATLAB BASE WORKSPACE
%=======================================================================

load('FPGA_POD_coefficients.mat');

Aw_Q  = int32(Aw_Q);
Bw_Q  = int32(Bw_Q);
A1_Q  = int32(A1_Q);
B10_Q = int32(B10_Q);
B11_Q = int32(B11_Q);
A2_Q  = int32(A2_Q);
B20_Q = int32(B20_Q);
B21_Q = int32(B21_Q);
K_Q   = int32(K_Q);

sample_valid = true;

fprintf('\nFPGA POD coefficients loaded into MATLAB workspace.\n');
fprintf('Use these variables as Constant-block inputs to the FIL block:\n');
fprintf('Aw_Q, Bw_Q, A1_Q, B10_Q, B11_Q, A2_Q, B20_Q, B21_Q, K_Q\n');
