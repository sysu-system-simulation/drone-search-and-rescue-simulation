function run_convergence(nUav, nReps)
% RUN_CONVERGENCE  How many replications are enough?
%
% Course Part 3 (Monte Carlo event simulation) shows the empirical estimate
% settling as the sample grows.  This script reproduces that behaviour for
% the search model: it re-uses one mission at a time, after each replication
% updates the running estimate of P_found and the Wilson half-width, and
% plots both.
%
% Two panels:
%   left  -- running estimate P_found(n) for the three strategies
%   right -- Wilson half-width vs n on log-log axes, against 1.96*sqrt(0.25/n)
%
% Saves figures/fig4_convergence.png and results/exp4_convergence.csv.

if nargin < 1 || isempty(nUav),  nUav  = 10;        end
if nargin < 2 || isempty(nReps), nReps = 400;       end

p  = config();
sc = make_scenario('open', p.mapSeed, p);

% One target sequence shared by the three strategies (common random numbers).
cdf = cumsum(sc.prior(:));
rng(p.targetSeed, 'twister');
u   = rand(nReps, 1);
tgt = zeros(nReps, 1);
for k = 1:nReps
    tgt(k) = find(cdf >= u(k), 1, 'first');
end

strats = {'parallel', 'prior', 'random'};
labels = {'Parallel track', 'Probability-based', 'Random walk'};
nS     = numel(strats);

P  = zeros(nReps, nS);
HW = zeros(nReps, nS);

for s = 1:nS
    % Match Experiment 1 stream for (strategy s, N = nUav)
    rng(p.targetSeed + 10000*s + 100*nUav, 'twister');
    hits = zeros(nReps, 1);
    for k = 1:nReps
        r = simulate_once(sc, strats{s}, nUav, p, tgt(k));
        hits(k)    = r.found;
        [P(k,s), HW(k,s)] = wilson_ci(sum(hits(1:k)), k);
    end
end

% --- report ----------------------------------------------------------------
fprintf('[convergence] N = %d, %d replications\n', nUav, nReps);
for s = 1:nS
    fprintf('    %-18s final P = %.4f +/- %.4f\n', labels{s}, P(end,s), HW(end,s));
end
fprintf('    half-width at n=50  : %.4f\n', mean(HW(50,:)));
fprintf('    half-width at n=400 : %.4f\n', mean(HW(end,:)));

% --- figure ----------------------------------------------------------------
fig = figure('Color', 'w', 'Position', [100 100 1100 430]);
cols = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.35 0.35 0.35];

subplot(1, 2, 1);
hold on;
for s = 1:nS
    plot(1:nReps, P(:,s), '-', 'Color', cols(s,:), 'LineWidth', 1.6);
end
hold off; box off; grid on;
xlabel('replications n'); ylabel('running estimate of P_{found}');
title(sprintf('Running estimate (N = %d)', nUav));
legend(labels, 'Location', 'east', 'Box', 'off');
ylim([0 1]);

subplot(1, 2, 2);
loglog(1:nReps, HW, 'LineWidth', 1.6);
hold on;
loglog(1:nReps, 1.96*sqrt(0.25./(1:nReps)), 'k--', 'LineWidth', 1.2);
hold off; box off; grid on; xlim([1 nReps]);
xlabel('replications n'); ylabel('Wilson half-width');
title('Uncertainty shrinks like 1/sqrt(n)');
legend([labels, {'1.96 sqrt(0.25/n)'}], 'Location', 'northeast', 'Box', 'off');

style_figure();

outPng = fullfile(fileparts(mfilename('fullpath')), 'figures', 'fig4_convergence.png');
exportgraphics(fig, outPng, 'Resolution', 200);
fprintf('    saved %s\n', outPng);

% --- data ------------------------------------------------------------------
T = table((1:nReps)', P(:,1), P(:,2), P(:,3), HW(:,1), HW(:,2), HW(:,3), ...
    'VariableNames', {'n', 'P_parallel', 'P_prior', 'P_random', ...
                      'hw_parallel', 'hw_prior', 'hw_random'});
outCsv = fullfile(fileparts(mfilename('fullpath')), 'results', 'exp4_convergence.csv');
writetable(T, outCsv);
fprintf('    saved %s\n', outCsv);
end
