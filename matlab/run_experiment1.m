% RUN_EXPERIMENT1 -- fleet-size saturation on the open map
%
% Question: how does P(target found) grow with the number of drones, and at
% what fleet size does adding another drone stop helping?
%
% Run in MATLAB:  run_experiment1     (or press Run)
%
% Outputs
%   results/exp1_fleet_size.csv
%   results/exp1_fleet_size.mat   (re-used by Experiments 2 and 3)
%   figures/fig1_fleet_size.png

clear; clc; close all;

p  = config();
sc = make_scenario('open', p.mapSeed, p);

names  = {'parallel', 'prior', 'random'};
labels = {'Parallel track', 'Probability-based', 'Random walk'};
nS = numel(names);

% ---- common random numbers: draw the target set once and reuse it --------
rng(p.targetSeed, 'twister');
cdf = cumsum(sc.prior(:));
u   = rand(p.reps, 1);
targets = zeros(p.reps, 1);
for k = 1:p.reps
    targets(k) = find(cdf >= u(k), 1);
end

P  = zeros(nS, p.nMax);      % detection probability
CI = zeros(nS, p.nMax);      % half-width of the 95% interval
COV = zeros(nS, p.nMax);     % mean fraction of the map visited

fprintf('Experiment 1: fleet-size saturation (%d replications per point)\n', p.reps);
fprintf('%4s %14s %14s %14s\n', 'N', labels{:});

for N = 1:p.nMax
    fprintf('%4d', N);
    for s = 1:nS
        % Isolate each (strategy, N) detection/movement RNG stream so identical
        % configurations yield identical results across Experiments 1-4.
        rng(p.targetSeed + 10000*s + 100*N, 'twister');
        hits = 0;  covSum = 0;
        for k = 1:p.reps
            r = simulate_once(sc, names{s}, N, p, targets(k));
            hits   = hits + r.found;
            covSum = covSum + r.coverage;
        end
        [P(s,N), CI(s,N)] = wilson_ci(hits, p.reps);
        COV(s,N) = covSum / p.reps;
        fprintf('  %6.3f +-%4.3f', P(s,N), CI(s,N));
    end
    fprintf('\n');
end

% ---- saturation point of every strategy ----------------------------------
Nstar   = zeros(1, nS);
plateau = zeros(1, nS);
for s = 1:nS
    [Nstar(s), plateau(s)] = optimal_n(P(s,:));
end
fprintf('\nSaturation fleet size N* (95%% of plateau):\n');
for s = 1:nS
    fprintf('  %-20s N* = %2d   plateau = %.3f\n', labels{s}, Nstar(s), plateau(s));
end

% ---- save ----------------------------------------------------------------
here   = fileparts(mfilename('fullpath'));
resDir = fullfile(here, 'results');
figDir = fullfile(here, 'figures');
if ~exist(resDir, 'dir'), mkdir(resDir); end
if ~exist(figDir, 'dir'), mkdir(figDir); end

T = table((1:p.nMax)', P(1,:)', CI(1,:)', P(2,:)', CI(2,:)', P(3,:)', CI(3,:)', ...
    'VariableNames', {'nUav', 'parallel', 'parallel_ci', ...
                      'prior', 'prior_ci', 'random', 'random_ci'});
writetable(T, fullfile(resDir, 'exp1_fleet_size.csv'));
save(fullfile(resDir, 'exp1_fleet_size.mat'), 'p', 'P', 'CI', 'COV', ...
     'Nstar', 'plateau', 'names', 'labels');

% ---- plot ----------------------------------------------------------------
figure('Color', 'w', 'Position', [100 100 860 500]);
hold on;
col = [0.11 0.42 0.75; 0.85 0.45 0.10; 0.35 0.35 0.35];
for s = 1:nS
    errorbar(1:p.nMax, P(s,:), CI(s,:), 'o-', 'Color', col(s,:), ...
        'LineWidth', 1.6, 'MarkerSize', 5, 'CapSize', 3);
end
for s = 1:nS
    xline(Nstar(s), '--', 'Color', col(s,:), 'LineWidth', 1.1);
end
grid on;  box on;
xlabel('Number of drones N');
ylabel('probability the target is found');
title(sprintf('Fleet-size saturation (open map, %d replications)', p.reps));
legend(labels, 'Location', 'southeast');
xlim([0.5 p.nMax+0.5]);  ylim([0 1]);
style_figure();
exportgraphics(gcf, fullfile(figDir, 'fig1_fleet_size.png'), 'Resolution', 300);

fprintf('\nSaved: results/exp1_fleet_size.csv\n');
fprintf('Saved: figures/fig1_fleet_size.png\n');
