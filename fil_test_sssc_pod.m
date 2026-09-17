clc;
clear;

%=======================================================================
% BASIC HDL VERIFIER FPGA-IN-THE-LOOP TEST
%
% IMPORTANT:
% 1. First generate the FIL System object using filWizard.
% 2. Replace "sssc_pod_controller_fil" below if HDL Verifier generates
%    a different class name.
% 3. Verify the generated input-port order before calling filObj(...).
%
% Expected logical data-input order used below:
%   sample_valid
%   dw1
%   dw2
%   coeff_aw
%   coeff_bw
%   coeff_a1
%   coeff_b10
%   coeff_b11
%   coeff_a2
%   coeff_b20
%   coeff_b21
%   coeff_k
%
% Outputs:
%   vq_ref
%   vq_ref_valid
%=======================================================================

load('FPGA_POD_coefficients.mat');

% FPGA-ready datatypes
Aw_Q  = int32(Aw_Q);
Bw_Q  = int32(Bw_Q);
A1_Q  = int32(A1_Q);
B10_Q = int32(B10_Q);
B11_Q = int32(B11_Q);
A2_Q  = int32(A2_Q);
B20_Q = int32(B20_Q);
B21_Q = int32(B21_Q);
K_Q   = int32(K_Q);

% ----------------------------------------------------------------------
% Create generated FIL object
% ----------------------------------------------------------------------
filObj = sssc_pod_controller_fil;

% Program ZedBoard
programFPGA(filObj);

fprintf('\nFPGA programmed. Starting simple POD test.\n');

% Example input sequence
N = 50;
DW1 = zeros(1,N);
DW2 = zeros(1,N);

% Small test disturbance
DW1(6:end) = 0.01;
DW2(6:end) = 0.002;

Vq_ref = zeros(1,N);
Vq_valid = false(1,N);

for k = 1:N

    dw1_q = double_to_q16(DW1(k));
    dw2_q = double_to_q16(DW2(k));

    % IMPORTANT:
    % Confirm this argument order against the generated FIL System object.
    [vq_q, valid] = filObj( ...
        true, ...
        dw1_q, ...
        dw2_q, ...
        Aw_Q, ...
        Bw_Q, ...
        A1_Q, ...
        B10_Q, ...
        B11_Q, ...
        A2_Q, ...
        B20_Q, ...
        B21_Q, ...
        K_Q);

    Vq_ref(k) = q16_to_double(vq_q);
    Vq_valid(k) = logical(valid);
end

fprintf('\nLast Vq_ref = %.12f\n', Vq_ref(end));
fprintf('Last valid  = %d\n', Vq_valid(end));

figure;
plot(1:N, Vq_ref, 'LineWidth', 1.5);
xlabel('Sample');
ylabel('Vq_{ref}');
title('FPGA POD FIL Test');
grid on;
