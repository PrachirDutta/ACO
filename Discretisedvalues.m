clc;
clear;

%% ============================================================
% LOAD OPTIMIZED POD PARAMETERS
% ============================================================

load('optimized_POD_parameters.mat');

fprintf('\n============================================\n');
fprintf(' OPTIMIZED CONTINUOUS POD PARAMETERS\n');
fprintf('============================================\n');

fprintf('K  = %.10f\n', K);
fprintf('Tw = %.10f\n', Tw);
fprintf('T1 = %.10f\n', T1);
fprintf('T2 = %.10f\n', T2);
fprintf('T3 = %.10f\n', T3);
fprintf('T4 = %.10f\n', T4);


%% ============================================================
% CONTROLLER SAMPLE TIME
%
% IMPORTANT:
% This must equal the sample time at which the FPGA POD receives
% a new DW1/DW2 sample.
% ============================================================

Ts = 0.001;          % Example: 1 ms
                     % CHANGE THIS TO YOUR ACTUAL SAMPLE TIME


fprintf('\nSampling Time Ts = %.10f s\n', Ts);


%% ============================================================
% TUSTIN DISCRETIZATION
%
%         2     1-z^-1
% s =    --- * -------
%         Ts    1+z^-1
% ============================================================

c = 2/Ts;


%% ============================================================
% WASHOUT FILTER
%
%          sTw
% ----------------------
%        1+sTw
%
% FPGA equation:
%
% yw[k] = Aw*yw[k-1]
%       + Bw*(x[k]-x[k-1])
% ============================================================

Aw = (c*Tw - 1)/(c*Tw + 1);

Bw = (c*Tw)/(c*Tw + 1);


%% ============================================================
% FIRST LEAD-LAG
%
%          1+sT1
% ----------------------
%          1+sT2
%
% FPGA equation:
%
% y1[k] = A1*y1[k-1]
%       + B10*yw[k]
%       + B11*yw[k-1]
% ============================================================

A1 = (c*T2 - 1)/(c*T2 + 1);

B10 = (1 + c*T1)/(1 + c*T2);

B11 = (1 - c*T1)/(1 + c*T2);


%% ============================================================
% SECOND LEAD-LAG
%
%          1+sT3
% ----------------------
%          1+sT4
%
% FPGA equation:
%
% y2[k] = A2*y2[k-1]
%       + B20*y1[k]
%       + B21*y1[k-1]
% ============================================================

A2 = (c*T4 - 1)/(c*T4 + 1);

B20 = (1 + c*T3)/(1 + c*T4);

B21 = (1 - c*T3)/(1 + c*T4);


%% ============================================================
% DISPLAY DISCRETE COEFFICIENTS
% ============================================================

fprintf('\n============================================\n');
fprintf(' DISCRETE POD COEFFICIENTS\n');
fprintf('============================================\n');

fprintf('Aw  = %.12f\n', Aw);
fprintf('Bw  = %.12f\n', Bw);

fprintf('A1  = %.12f\n', A1);
fprintf('B10 = %.12f\n', B10);
fprintf('B11 = %.12f\n', B11);

fprintf('A2  = %.12f\n', A2);
fprintf('B20 = %.12f\n', B20);
fprintf('B21 = %.12f\n', B21);

fprintf('K   = %.12f\n', K);


%% ============================================================
% CONVERT TO SIGNED Q16.16
%
% FPGA integer = real_value * 2^16
% ============================================================

FRAC_BITS = 16;
SCALE = 2^FRAC_BITS;

Aw_Q  = int32(round(Aw  * SCALE));
Bw_Q  = int32(round(Bw  * SCALE));

A1_Q  = int32(round(A1  * SCALE));
B10_Q = int32(round(B10 * SCALE));
B11_Q = int32(round(B11 * SCALE));

A2_Q  = int32(round(A2  * SCALE));
B20_Q = int32(round(B20 * SCALE));
B21_Q = int32(round(B21 * SCALE));

K_Q   = int32(round(K   * SCALE));


%% ============================================================
% DISPLAY FPGA VALUES
% ============================================================

fprintf('\n============================================\n');
fprintf(' Q16.16 VALUES FOR ZEDBOARD FPGA\n');
fprintf('============================================\n');

fprintf('Aw_Q  = %d\n', Aw_Q);
fprintf('Bw_Q  = %d\n', Bw_Q);

fprintf('A1_Q  = %d\n', A1_Q);
fprintf('B10_Q = %d\n', B10_Q);
fprintf('B11_Q = %d\n', B11_Q);

fprintf('A2_Q  = %d\n', A2_Q);
fprintf('B20_Q = %d\n', B20_Q);
fprintf('B21_Q = %d\n', B21_Q);

fprintf('K_Q   = %d\n', K_Q);


%% ============================================================
% OPTIONAL CHECK
%
% Convert Q16.16 back to decimal to see quantization error.
% ============================================================

fprintf('\n============================================\n');
fprintf(' Q16.16 BACK-CONVERSION CHECK\n');
fprintf('============================================\n');

fprintf('Aw  = %.12f\n', double(Aw_Q)/SCALE);
fprintf('Bw  = %.12f\n', double(Bw_Q)/SCALE);

fprintf('A1  = %.12f\n', double(A1_Q)/SCALE);
fprintf('B10 = %.12f\n', double(B10_Q)/SCALE);
fprintf('B11 = %.12f\n', double(B11_Q)/SCALE);

fprintf('A2  = %.12f\n', double(A2_Q)/SCALE);
fprintf('B20 = %.12f\n', double(B20_Q)/SCALE);
fprintf('B21 = %.12f\n', double(B21_Q)/SCALE);

fprintf('K   = %.12f\n', double(K_Q)/SCALE);


%% ============================================================
% SAVE FPGA-READY VALUES
% ============================================================

save('FPGA_POD_coefficients.mat', ...
    'Aw_Q','Bw_Q', ...
    'A1_Q','B10_Q','B11_Q', ...
    'A2_Q','B20_Q','B21_Q', ...
    'K_Q', ...
    'Ts');


fprintf('\nFPGA coefficients saved to FPGA_POD_coefficients.mat\n');