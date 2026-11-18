% RUN_EXPERIMENT2 -- strategy comparison across terrains
%
% Question: with each strategy running at its own saturation fleet size N*
% (found in Experiment 1), does the ranking of the strategies survive when
% the terrain changes?
%
% Run run_experiment1 first (it writes results/exp1_fleet_size.mat).
%
% Outputs
%   results/exp2_terrain.csv
%   figures/fig2_terrain.png

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

terrainKinds = {'open', 'forest', 'urban', 'mixed'};
terrainNames = {'Open', 'Forest', 'Urban', 'Mixed'};
nT = numel(terrainKinds);
nS = numel(names);

P  = zeros(nT, nS);
CI = zeros(nT, nS);

fprintf('Experiment 2: strategy comparison at each strategy''s own N*\n');
fprintf('  N*: ');
for s = 1:nS
    fprintf('%s=%d  ', names{s}, Nstar(s));
end
fprintf('\n\n%8s', 'Terrain');
fprintf('%18s', labels{:});
fprintf('\n');

for t = 1:nT
    sc = make_scenario(terrainKinds{t}, p.mapSeed, p);

    % fresh target set, drawn from THIS terrain's prior
    rng(p.targetSeed, 'twister');
    cdf = cumsum(sc.prior(:));
    u   = rand(p.reps, 1);
    targets = zeros(p.reps, 1);
    for k = 1:p.reps
        targets(k) = find(cdf >= u(k), 1);
    end

    fprintf('%8s', terrainNames{t});
    for s = 1:nS
        hits = 0;
        for k = 1:p.reps
            r = simulate_once(sc, names{s}, Nstar(s), p, targets(k));
            hits = hits + r.found;
        end
        [P(t,s), CI(t,s)] = wilson_ci(hits, p.reps);
        fprintf('  %6.3f +-%4.3f', P(t,s), CI(t,s));
    end
    fprintf('\n');
end

% ---- save ----------------------------------------------------------------
T = table(terrainNames', P(:,1), CI(:,1), P(:,2), CI(:,2), P(:,3), CI(:,3), ...
    'VariableNames', {'terrain', 'parallel', 'parallel_ci', ...
                      'prior', 'prior_ci', 'random', 'random_ci'});
writetable(T, fullfile(resDir, 'exp2_terrain.csv'));

% ---- plot ----------------------------------------------------------------
figure('Color', 'w', 'Position', [100 100 960 500]);
hb = bar(1:nT, P, 'grouped');
hold on;
col = [0.11 0.42 0.75; 0.85 0.45 0.10; 0.35 0.35 0.35];
for s = 1:nS
    hb(s).FaceColor = col(s,:);
    x = hb(s).XEndPoints;
    errorbar(x, P(:,s)', CI(:,s)', 'k.', 'LineWidth', 1);
end
set(gca, 'XTick', 1:nT, 'XTickLabel', terrainNames);
grid on;  box on;
ylabel('probability the target is found');
title('Strategy comparison across terrains (each at its own N*)');
legend(labels, 'Location', 'northeastoutside');
ylim([0 1]);
style_figure();
exportgraphics(gcf, fullfile(figDir, 'fig2_terrain.png'), 'Resolution', 300);

fprintf('\nSaved: results/exp2_terrain.csv\n');
fprintf('Saved: figures/fig2_terrain.png\n');
