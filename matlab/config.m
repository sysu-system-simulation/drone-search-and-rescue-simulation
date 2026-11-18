function p = config()
% CONFIG  Every tunable number of the simulation lives here.
% The other files only read this struct, so you can change the experiment
% without touching the model code.

% ---- map / geometry --------------------------------------------------------
p.H = 40;                 % map height in cells
p.W = 40;                 % map width in cells
p.cellSize = 100;         % metres per cell  (40 cells = 4 km)
p.base = [20 20];         % launch cell (map centre)

% ---- time -----------------------------------------------------------------
p.dt   = 20;              % seconds per simulation step
p.tMax = 300;             % steps per mission (300 x 20 s = 100 min)

% ---- sensor ---------------------------------------------------------------
% Sweep width W is the width of the strip a sensor effectively covers,
% measured in cells.  Track spacing is 1 cell, so the coverage ratio of a
% single pass is C = W/1 and the detection probability of one pass is
%      p = 1 - exp(-C)
% (Koopman's random-search / poor-conditions curve -- deliberately
% conservative, see research-notes.md Finding 3.)
p.sweepW = 1.0;                              % open-terrain sweep width (cells)
p.terrainMult = [1.00 0.55 0.45 0.20];       % open forest urban water
p.blockSize = 8;                             % side of a search block (cells)

% ---- Monte Carlo ----------------------------------------------------------
p.reps       = 400;       % replications per configuration
p.nMax       = 20;        % largest fleet size tested
p.mapSeed    = 7;         % scenario seed
p.targetSeed = 1000;      % target-draw seed (common random numbers)
end
