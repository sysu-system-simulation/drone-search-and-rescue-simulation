% RUN_EXPERIMENT3 -- sensitivity to sensor quality (sweep width)
%
% Question: how much does the answer depend on the sweep width W?  W is the
% least certain input of the model, so we re-run the open-map experiment
% with W halved and doubled (the block size and fleet sizes stay fixed).
%
% Run run_experiment1 first (it writes results/exp1_fleet_size.mat).
%
% Outputs
%   results/exp3_sweep_width.csv
%   figures/fig3_sweep_width.png

clear; clc; close all;

here   = fileparts(mfilename('fullpath'));
resDir = fullfile(here, 'results');
figDir = fullfile(here, 'figures');
matFile = fullfile(resDir, 'exp1_fleet_size.mat');

if ~exist(matFile, 'file')
    error('Run run_experiment1 first: %s not found.', matFile);
end
load(matFile, 'Nstar', 'names', 'labels');

p = config();

scales  = [0.5 1 2];
scaleNames = {'W x 0.5', 'W x 1 (base)', 'W x 2'};
nW = numel(scales);
nS = numel(names);

P  = zeros(nW, nS);
CI = zeros(nW, nS);

fprintf('Experiment 3: sweep-width sensitivity (open map, each strategy at N*)\n\n');
fprintf('%14s', 'W scale');
fprintf('%18s', labels{:});
fprintf('\n');

for w = 1:nW
    sc = make_scenario('open', p.mapSeed, p, scales(w));

    rng(p.targetSeed, 'twister');
    cdf = cumsum(sc.prior(:));
    u   = rand(p.reps, 1);
    targets = zeros(p.reps, 1);
    for k = 1:p.reps
        targets(k) = find(cdf >= u(k), 1);
    end

    fprintf('%14s', scaleNames{w});
    for s = 1:nS
        hits = 0;
        for k = 1:p.reps
            r = simulate_once(sc, names{s}, Nstar(s), p, targets(k));
            hits = hits + r.found;
        end
        [P(w,s), CI(w,s)] = wilson_ci(hits, p.reps);
        fprintf('  %6.3f +-%4.3f', P(w,s), CI(w,s));
    end
    fprintf('\n');
end

% ---- show what the sensor change actually means --------------------------
% one pass over an open cell: p = 1 - exp(-W)
fprintf('\nOne-pass detection probability, open terrain:\n');
for w = 1:nW
    fprintf('  %-14s p = 1 - exp(-%.2f) = %.3f\n', ...
        scaleNames{w}, p.sweepW * scales(w), ...
        1 - exp(-p.sweepW * scales(w)));
end

% ---- save ----------------------------------------------------------------
T = table(scales', P(:,1), CI(:,1), P(:,2), CI(:,2), P(:,3), CI(:,3), ...
    'VariableNames', {'sweepScale', 'parallel', 'parallel_ci', ...
                      'prior', 'prior_ci', 'random', 'random_ci'});
writetable(T, fullfile(resDir, 'exp3_sweep_width.csv'));

% ---- plot ----------------------------------------------------------------
figure('Color', 'w', 'Position', [100 100 860 500]);
hold on;
col = [0.11 0.42 0.75; 0.85 0.45 0.10; 0.35 0.35 0.35];
for s = 1:nS
    errorbar(scales, P(:,s), CI(:,s), 'o-', 'Color', col(s,:), ...
        'LineWidth', 1.6, 'MarkerSize', 5, 'CapSize', 3);
end
grid on;  box on;
set(gca, 'XTick', scales, 'XTickLabel', scaleNames);
xlabel('Sweep-width multiplier');
ylabel('probability the target is found');
title('Sensitivity to sensor quality (open map)');
legend(labels, 'Location', 'southeast');
ylim([0 1]);
style_figure();
exportgraphics(gcf, fullfile(figDir, 'fig3_sweep_width.png'), 'Resolution', 300);

fprintf('\nSaved: results/exp3_sweep_width.csv\n');
fprintf('Saved: figures/fig3_sweep_width.png\n');
