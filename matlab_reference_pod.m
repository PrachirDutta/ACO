function [vq_ref, state] = matlab_reference_pod(dw1, dw2, coeff, state)
%MATLAB_REFERENCE_POD Floating-point reference of the FPGA difference equations.
%
% coeff fields:
%   Aw, Bw, A1, B10, B11, A2, B20, B21, K
%
% state fields:
%   delta_w_prev, yw_prev, y1_prev, y2_prev
%
% Use this to verify the FPGA algorithm sample-by-sample.

delta_w = dw1 - dw2;

dx = delta_w - state.delta_w_prev;

yw = coeff.Aw * state.yw_prev ...
   + coeff.Bw * dx;

y1 = coeff.A1  * state.y1_prev ...
   + coeff.B10 * yw ...
   + coeff.B11 * state.yw_prev;

y2 = coeff.A2  * state.y2_prev ...
   + coeff.B20 * y1 ...
   + coeff.B21 * state.y1_prev;

vq_ref = coeff.K * y2;

state.delta_w_prev = delta_w;
state.yw_prev = yw;
state.y1_prev = y1;
state.y2_prev = y2;

end
