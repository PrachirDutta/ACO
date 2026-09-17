function y = q16_to_double(x)
%Q16_TO_DOUBLE Convert signed Q16.16 int32 values to MATLAB double.

y = double(x) / 2^16;

end
