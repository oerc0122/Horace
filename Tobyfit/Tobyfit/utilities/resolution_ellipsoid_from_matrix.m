function M = resolution_ellipsoid_from_matrix(M,frac)
if nargin < 2 || ~isnumeric(frac)
    frac=0.5; % half-height probability by default
end
% The elements of M are inverse squared Gaussian widths, i.e., 1/sigma_ij^2
% but we would like to consider fractional-height equal-probability widths,
% where the 'half-width fractional-height' (hwfh) is
%   hwfh = sqrt(2)*log(1/fraction) * sigma
% We must therefore multiply inv(C) by (sigma/hwfh)^2 = 1/2/log(1/fraction)^2
% We must therefore divide M by (hwfh/sigma)^2 = 2*log(1/fraction)^2
M = M / (2*log(1/frac)^2);
end
