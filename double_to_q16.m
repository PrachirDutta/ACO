function y = double_to_q16(x)
%DOUBLE_TO_Q16 Convert MATLAB double/single values to signed Q16.16 int32.

SCALE = 2^16;

temp = round(double(x) * SCALE);
temp = min(temp, double(intmax('int32')));
temp = max(temp, double(intmin('int32')));

y = int32(temp);

end
