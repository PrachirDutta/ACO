clc;
clear;


%=======================================================================

load('optimized_POD_parameters.mat');

requiredVars = {'K','Tw','T1','T2','T3','T4'};
for k = 1:numel(requiredVars)
    if ~exist(requiredVars{k}, 'var')
        error('Missing variable "%s" in optimized_POD_parameters.mat.', requiredVars{k});
    end
end

% ----------------------------------------------------------------------
% SET  CONTROLLER SAMPLE TIME HERE
% ----------------------------------------------------------------------
Ts = 0.001;   

if Ts <= 0
    error('Ts must be greater than zero.');
end

fprintf('\n============================================\n');
fprintf(' OPTIMIZED CONTINUOUS POD PARAMETERS\n');
fprintf('============================================\n');
fprintf('K  = %.12f\n', K);
fprintf('Tw = %.12f s\n', Tw);
fprintf('T1 = %.12f s\n', T1);
fprintf('T2 = %.12f s\n', T2);
fprintf('T3 = %.12f s\n', T3);
fprintf('T4 = %.12f s\n', T4);
fprintf('Ts = %.12f s\n', Ts);

% ----------------------------------------------------------------------
% Tustin substitution:
%
%            2     1-z^-1
% s =       --- * -------
%            Ts    1+z^-1
% ----------------------------------------------------------------------
c = 2/Ts;

% Washout:
% yw[k] = Aw*yw[k-1] + Bw*(x[k]-x[k-1])
Aw = (c*Tw - 1)/(c*Tw + 1);
Bw = (c*Tw)/(c*Tw + 1);

% Lead-lag 1:
% y1[k] = A1*y1[k-1] + B10*yw[k] + B11*yw[k-1]
A1  = (c*T2 - 1)/(c*T2 + 1);
B10 = (1 + c*T1)/(1 + c*T2);
B11 = (1 - c*T1)/(1 + c*T2);

% Lead-lag 2:
% y2[k] = A2*y2[k-1] + B20*y1[k] + B21*y1[k-1]
A2  = (c*T4 - 1)/(c*T4 + 1);
B20 = (1 + c*T3)/(1 + c*T4);
B21 = (1 - c*T3)/(1 + c*T4);

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

% ----------------------------------------------------------------------
% Q16.16 conversion
% ----------------------------------------------------------------------
FRAC_BITS = 16;
SCALE = 2^FRAC_BITS;

toQ16 = @(x) int32(max(double(intmin('int32')), ...
                 min(double(intmax('int32')), round(double(x)*SCALE))));

Aw_Q  = toQ16(Aw);
Bw_Q  = toQ16(Bw);
A1_Q  = toQ16(A1);
B10_Q = toQ16(B10);
B11_Q = toQ16(B11);
A2_Q  = toQ16(A2);
B20_Q = toQ16(B20);
B21_Q = toQ16(B21);
K_Q   = toQ16(K);

fprintf('\n============================================\n');
fprintf(' FPGA Q16.16 COEFFICIENTS\n');
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

fprintf('\n============================================\n');
fprintf(' Q16.16 BACK-CONVERSION CHECK\n');
fprintf('============================================\n');
fprintf('Aw  -> %.12f\n', double(Aw_Q)/SCALE);
fprintf('Bw  -> %.12f\n', double(Bw_Q)/SCALE);
fprintf('A1  -> %.12f\n', double(A1_Q)/SCALE);
fprintf('B10 -> %.12f\n', double(B10_Q)/SCALE);
fprintf('B11 -> %.12f\n', double(B11_Q)/SCALE);
fprintf('A2  -> %.12f\n', double(A2_Q)/SCALE);
fprintf('B20 -> %.12f\n', double(B20_Q)/SCALE);
fprintf('B21 -> %.12f\n', double(B21_Q)/SCALE);
fprintf('K   -> %.12f\n', double(K_Q)/SCALE);

save('FPGA_POD_coefficients.mat', ...
     'Aw_Q','Bw_Q','A1_Q','B10_Q','B11_Q', ...
     'A2_Q','B20_Q','B21_Q','K_Q', ...
     'Aw','Bw','A1','B10','B11','A2','B20','B21', ...
     'K','Tw','T1','T2','T3','T4','Ts','FRAC_BITS');

fprintf('\nSaved: FPGA_POD_coefficients.mat\n');
