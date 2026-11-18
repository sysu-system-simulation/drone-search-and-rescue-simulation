function [res, trace] = animate_search(kind, strat, nUav, delay)
% ANIMATE_SEARCH  Replay one simulated drone search.
%   animate_search('mixed', 'parallel', 5) shows five drones searching.
%   Strategies are 'parallel', 'prior', and 'random'. The optional fourth
%   argument sets the pause between steps in seconds (default 0.05).

if nargin < 1 || isempty(kind), kind = 'mixed'; end
if nargin < 2 || isempty(strat), strat = 'parallel'; end
if nargin < 3 || isempty(nUav), nUav = 5; end
if nargin < 4 || isempty(delay), delay = 0.05; end

validateattributes(nUav, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 20});
validateattributes(delay, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});

p = config();
sc = make_scenario(kind, p.mapSeed, p);
rng(p.targetSeed, 'twister');
[res, trace] = simulate_once(sc, strat, nUav, p);

fig = figure('Color', 'w', 'Name', 'Drone search', 'NumberTitle', 'off');
ax = axes('Parent', fig);
imagesc(ax, sc.terrain);
colormap(ax, [0.85 0.92 0.75; 0.45 0.68 0.45; 0.72 0.72 0.72; 0.60 0.78 0.92]);
caxis(ax, [0.5 4.5]);
axis(ax, 'image');
hold(ax, 'on');
contour(ax, sc.prior, 4, 'LineColor', [0.75 0.15 0.15], 'LineWidth', 1);
visited = false(p.H, p.W);
shade = imagesc(ax, zeros(p.H, p.W, 3));
set(shade, 'AlphaData', zeros(p.H, p.W));
plot(ax, p.base(2), p.base(1), 'p', 'MarkerSize', 12, ...
    'MarkerFaceColor', [0.95 0.85 0.2], 'MarkerEdgeColor', 'k');
drones = plot(ax, repmat(p.base(2), 1, nUav), repmat(p.base(1), 1, nUav), ...
    'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.1 0.35 0.9], 'MarkerEdgeColor', 'w', 'LineStyle', 'none');
target = plot(ax, NaN, NaN, 'r*', 'MarkerSize', 14, 'LineWidth', 2);
xlabel(ax, 'Cell column');
ylabel(ax, 'Cell row');
legend(ax, [drones, target], {'Drones', 'Person found'}, 'Location', 'eastoutside');

for t = 1:p.tMax
    if ~isgraphics(fig), return; end
    idx = sub2ind([p.H p.W], trace.rows(t, :), trace.cols(t, :));
    visited(idx) = true;
    set(shade, 'AlphaData', 0.22 * double(visited));
    set(drones, 'XData', trace.cols(t, :), 'YData', trace.rows(t, :));
    if res.found && t >= res.tFound
        set(target, 'XData', trace.target(2), 'YData', trace.target(1));
        status = sprintf('Person found at %.1f min', res.tFound * p.dt / 60);
    else
        status = 'Searching';
    end
    if t == p.tMax && ~res.found
        status = 'Person not found';
    end
    title(ax, sprintf('%s / %s | %.1f min | %s', kind, strat, t * p.dt / 60, status));
    drawnow;
    if delay > 0, pause(delay); end
end
end
