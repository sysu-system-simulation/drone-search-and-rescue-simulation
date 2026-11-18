function [Nstar, plateau] = optimal_n(P)
% OPTIMAL_N  Where does adding drones stop paying off?
%
% Definition used in the paper:
%   N* is the smallest fleet size whose detection probability reaches 95%
%   of the plateau P(Nmax).  The curve is first smoothed with a 3-point
%   moving average and the plateau is the mean of the last three smoothed
%   points.
%
% Why the smoothing: a single replication sequence can put a 2-3 pp bump on
% one fleet size, and without smoothing N* jumps between neighbouring values
% from one run to the next.  Averaging three points removes that bump.
%
% This is an OPERATIONAL definition, not a discovery: there is no
% closed-form optimal fleet size (research-notes.md, Finding 5), so the
% saturation point has to be defined before it can be measured.

n = numel(P);

Ps = P;
if n >= 3
    Ps(2:n-1) = (P(1:n-2) + P(2:n-1) + P(3:n)) / 3;
end

plateau = mean(Ps(max(1, n-2):n));

idx = find(Ps >= 0.95 * plateau, 1, 'first');
if isempty(idx)
    Nstar = n;
else
    Nstar = idx;
end
end
