function validate_sim()
% VALIDATE_SIM  Self-checks of the simulation (verification, not validation).
%
% Each check tests one thing the paper claims.  Run it before trusting any
% experiment output:
%
%     >> validate_sim
%
% A check prints PASS or FAIL; the summary at the end must be all PASS.

clc;
p = config();
nPass = 0;  nCheck = 0;

fprintf('=== validate_sim: model self-checks ===\n\n');

%% 1. scenario integrity ---------------------------------------------------
kinds = {'open', 'forest', 'urban', 'mixed'};
ok = true;
for i = 1:numel(kinds)
    sc = make_scenario(kinds{i}, p.mapSeed, p);
    ok = ok && abs(sum(sc.prior(:)) - 1) < 1e-9;
    ok = ok && all(sc.detP(:) > 0) && all(sc.detP(:) < 1);
    ok = ok && all(ismember(unique(sc.terrain(:)), 1:4));
    expected = 1 - exp(-p.sweepW * p.terrainMult(sc.terrain));
    ok = ok && max(abs(sc.detP(:) - expected(:))) < 1e-12;
end
[nPass, nCheck] = report('scenario: prior sums to 1, detP matches 1-exp(-W)', ok, nPass, nCheck);

%% 2. detection formula is implemented correctly inside simulate_once -------
% Place a single target at (19,19) (reached on step t=1 by a parallel drone
% launching from base (20,20) toward (1,1)) and verify simulate_once reproduces
% sc.detP(19,19) across independent 1-step missions.
sc = make_scenario('open', p.mapSeed, p);
pOne = p;
pOne.tMax = 1;
tgt1 = sub2ind([p.H p.W], p.base(1) - 1, p.base(2) - 1);
p0 = sc.detP(p.base(1) - 1, p.base(2) - 1);
n  = 4000;
rng(42, 'twister');
hits = 0;
for k = 1:n
    r = simulate_once(sc, 'parallel', 1, pOne, tgt1);
    hits = hits + r.found;
end
se   = sqrt(p0*(1-p0)/n);
ok   = abs(hits/n - p0) < 3*se;
fprintf('       target p = %.4f, simulated %.4f (3*SE = %.4f)\n', p0, hits/n, 3*se);
[nPass, nCheck] = report('detection: simulate_once reproduces the per-pass p', ok, nPass, nCheck);

%% 3. independent whole-map searchers follow the independence bound ---------
% The bound P_N = 1-(1-P1)^N only applies when every drone runs the SAME
% whole-map search independently.  That is the random-walk baseline.
% It must NOT be applied to parallel track: there each drone owns a band
% that shrinks with N, so its per-drone search effort is not P1.
nVal = p.reps;
rng(p.targetSeed, 'twister');
cdf = cumsum(sc.prior(:));
u = rand(nVal, 1);
targets = arrayfun(@(x) find(cdf >= x, 1), u);

Ns = [1 2 4];
Pf = zeros(1, numel(Ns));
for j = 1:numel(Ns)
    rng(p.targetSeed + 30000 + 100*Ns(j), 'twister');
    hits = 0;
    for k = 1:nVal
        r = simulate_once(sc, 'random', Ns(j), p, targets(k));
        hits = hits + r.found;
    end
    Pf(j) = hits / nVal;
end
bound   = 1 - (1 - Pf(1)).^Ns;
seP     = sqrt(Pf .* (1 - Pf) / nVal);
seBound = Ns .* (1 - Pf(1)).^(Ns - 1) * seP(1);
margin  = 3 * sqrt(seP.^2 + seBound.^2);
ok = all(Pf <= bound + margin);   % overlap can only lower P, never raise it
fprintf('       P = [%.3f %.3f %.3f], independence bound = [%.3f %.3f %.3f]\n', ...
    Pf(1), Pf(2), Pf(3), bound(1), bound(2), bound(3));
[nPass, nCheck] = report('overlap: random-walk fleet stays below 1-(1-P1)^N', ok, nPass, nCheck);

%% 4. coverage grows with the fleet ----------------------------------------
covMean = zeros(1, 2);
for j = 1:2
    N = [2 5];
    s = 0;
    for k = 1:50
        r = simulate_once(sc, 'parallel', N(j), p, targets(k));
        s = s + r.coverage;
    end
    covMean(j) = s / 50;
end
ok = covMean(2) > covMean(1);
fprintf('       coverage N=2: %.3f, N=5: %.3f\n', covMean(1), covMean(2));
[nPass, nCheck] = report('coverage: a larger systematic fleet covers more', ok, nPass, nCheck);

%% 5. reproducibility with a fixed seed ------------------------------------
rng(123, 'twister');
a = simulate_once(sc, 'prior', 5, p, targets(1));
rng(123, 'twister');
b = simulate_once(sc, 'prior', 5, p, targets(1));
sameT = (isnan(a.tFound) && isnan(b.tFound)) || (a.tFound == b.tFound);
ok = (a.found == b.found) && sameT;
[nPass, nCheck] = report('reproducibility: same seed gives the same mission', ok, nPass, nCheck);

%% 6. saturation rule behaves on a known curve -----------------------------
Ptest = 0.9 * (1 - exp(-(1:20)/3));
[Nstar, ~] = optimal_n(Ptest);
ok = Nstar >= 4 && Nstar <= 12;
fprintf('       synthetic saturation curve -> N* = %d\n', Nstar);
[nPass, nCheck] = report('optimal_n: finds the knee of a known curve', ok, nPass, nCheck);

%% summary -----------------------------------------------------------------
fprintf('\n%d / %d checks passed.\n', nPass, nCheck);
if nPass == nCheck
    fprintf('Model verified: the experiments can be trusted as an implementation\n');
    fprintf('of the stated assumptions.  (Validation against real SAR data is\n');
    fprintf('outside the scope of this project.)\n');
else
    warning('Some checks failed - fix them before using the results.');
end
end

% -------------------------------------------------------------------------
function [nPass, nCheck] = report(label, ok, nPass, nCheck)
nCheck = nCheck + 1;
if ok
    nPass = nPass + 1;
    fprintf('[PASS] %s\n', label);
else
    fprintf('[FAIL] %s\n', label);
end
end
