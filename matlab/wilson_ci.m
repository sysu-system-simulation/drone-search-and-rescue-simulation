function [phat, half, lo, hi] = wilson_ci(k, n, z)
% WILSON_CI  Wilson score confidence interval for a proportion.
%   k : successes, n : trials, z : normal quantile (default 1.96 = 95%)
%
% Returns the raw estimate phat = k/n and a symmetric half-width that
% covers the Wilson interval.  Wilson is used instead of
% phat +/- z*sqrt(phat(1-phat)/n) because the simple formula collapses
% when phat is near 0 or 1, which happens for small fleets.
% Optional outputs lo and hi are the Wilson interval endpoints.

if nargin < 3 || isempty(z)
    z = 1.96;
end

phat   = k / n;
denom  = 1 + z^2 / n;
centre = (phat + z^2/(2*n)) / denom;
hw     = z * sqrt(phat*(1-phat)/n + z^2/(4*n^2)) / denom;

lo   = max(0, centre - hw);
hi   = min(1, centre + hw);
half = max(phat - lo, hi - phat);
end
