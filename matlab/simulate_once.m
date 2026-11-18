function res = simulate_once(sc, strat, nUav, p, tgtIdx)
% SIMULATE_ONCE  Run ONE mission of the fleet (one Monte Carlo replication).
%
%   strat  : 'parallel' | 'prior' | 'random'
%   nUav   : number of drones
%   tgtIdx : optional linear index of the target cell.  Passing the same
%            index to several strategies is "common random numbers": every
%            strategy then faces exactly the same target.
%
% Model notes
%   * one step = one cell = 100 m; the drone's own cell is the only cell it
%     can detect the target in.  The sweep width is folded into detP, so a
%     pass over a cell detects the target with probability sc.detP(cell).
%   * every visit is a fresh independent trial, therefore k passes give
%     P = 1 - (1-p)^k, which is the k-pass form of Koopman's curve.
%   * all drones launch from the same base cell.

H = p.H;  W = p.W;

% ---------- 0. target ------------------------------------------------------
if nargin < 5 || isempty(tgtIdx)
    cdf = cumsum(sc.prior(:));
    tgtIdx = find(cdf >= rand(), 1);
end
[tr, tc] = ind2sub([H W], tgtIdx);
pTarget  = sc.detP(tr, tc);

% ---------- 1. plans -------------------------------------------------------
isParallel = strcmp(strat, 'parallel');
isPrior    = strcmp(strat, 'prior');
isRandom   = strcmp(strat, 'random');

posR = p.base(1) * ones(1, nUav);
posC = p.base(2) * ones(1, nUav);
visited = false(H, W);

if isParallel
    edges = round(linspace(0, H, nUav + 1));
    plans = cell(1, nUav);
    for i = 1:nUav
        r0 = edges(i) + 1;
        r1 = max(edges(i+1), r0);
        plans{i} = boustrophedon(r0, r1, 1, W);
    end
    slot = 1:nUav;
    ptr  = ones(1, nUav);
elseif isPrior
    plans     = rank_blocks(sc.prior, p.blockSize);
    nextBlock = 1;
    slot      = zeros(1, nUav);
    ptr       = ones(1, nUav);
elseif ~isRandom
    error('simulate_once: unknown strategy "%s"', strat);
end

found  = false;
tFound = NaN;

% ---------- 2. time loop ---------------------------------------------------
for t = 1:p.tMax
    for i = 1:nUav

        if isRandom
            posR(i) = min(max(posR(i) + randi([-1 1]), 1), H);
            posC(i) = min(max(posC(i) + randi([-1 1]), 1), W);

        else
            % pick the next block when the previous one is finished
            if isPrior
                if slot(i) == 0 || ptr(i) > size(plans{slot(i)}, 1)
                    slot(i) = nextBlock;
                    nextBlock = nextBlock + 1;
                    if nextBlock > numel(plans)
                        nextBlock = 1;                 % next sweep round
                    end
                    ptr(i) = 1;
                end
            end
            if isParallel && ptr(i) > size(plans{i}, 1)
                ptr(i) = 1;                            % cyclic re-sweep
            end

            path = plans{slot(i)};
            gr = path(ptr(i), 1);
            gc = path(ptr(i), 2);

            % one king-move toward the waypoint
            posR(i) = posR(i) + sign(gr - posR(i));
            posC(i) = posC(i) + sign(gc - posC(i));

            if posR(i) == gr && posC(i) == gc
                ptr(i) = ptr(i) + 1;
            end
        end

        visited(posR(i), posC(i)) = true;

        % detection trial: only on the target cell, one trial per visit
        if ~found && posR(i) == tr && posC(i) == tc
            if rand() < pTarget
                found  = true;
                tFound = t;
            end
        end
    end
end

% The mission is NOT cut short when the target is found: every replication
% must run the same 300 steps, otherwise "coverage" would be censored and a
% faster fleet would look like it covered less of the map.
res.found    = found;
res.tFound   = tFound;
res.coverage = mean(visited(:));
end
