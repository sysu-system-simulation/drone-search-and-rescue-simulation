function plot_scenario(kind, nUav)
% PLOT_SCENARIO  Draw one search map: terrain, search prior, and the routes
% the parallel-track strategy would fly with nUav drones.
%
% Use it to produce the "scenario" figure of the paper:
%
%     >> plot_scenario('mixed', 5)
%
% The figure is also written to figures/fig0_scenario.png

if nargin < 1, kind = 'mixed'; end
if nargin < 2, nUav = 5;       end

p  = config();
sc = make_scenario(kind, p.mapSeed, p);
H = p.H;  W = p.W;

cmap = [0.85 0.92 0.75;      % open
        0.45 0.68 0.45;      % forest
        0.72 0.72 0.72;      % urban
        0.60 0.78 0.92];     % water

figure('Color', 'w', 'Position', [100 100 620 540]);
imagesc(sc.terrain);
colormap(cmap);  caxis([0.5 4.5]);
axis image;  hold on;

% prior as red contours
[~, hc] = contour(sc.prior, 4, 'LineColor', [0.75 0.15 0.15], 'LineWidth', 1.1);
if ~isempty(hc), hc.ShowText = 'off'; end

% parallel-track routes
edges = round(linspace(0, H, nUav + 1));
for i = 1:nUav
    r0 = edges(i) + 1;
    r1 = max(edges(i+1), r0);
    path = boustrophedon(r0, r1, 1, W);
    plot(path(:,2), path(:,1), '-', 'Color', [0.10 0.10 0.10], 'LineWidth', 0.8);
end

% base
plot(p.base(2), p.base(1), 'p', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.95 0.85 0.2], 'MarkerEdgeColor', 'k');

xlabel('cell column');  ylabel('cell row');
title(sprintf('%s map: terrain, search prior (red) and %d parallel tracks', ...
    kind, nUav));

here   = fileparts(mfilename('fullpath'));
figDir = fullfile(here, 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end
exportgraphics(gcf, fullfile(figDir, sprintf('fig0_scenario_%s.png', kind)), ...
    'Resolution', 300);
fprintf('Saved: figures/fig0_scenario_%s.png\n', kind);
end
