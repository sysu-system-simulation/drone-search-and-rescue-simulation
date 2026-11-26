function metrics = check_sampling(kind, nDraws)
% CHECK_SAMPLING  Validate random-variate generation (course Part 3: inverse transform).
%
% The target cell is drawn with the inverse transform method:
%   F(x) = cumulated prior over cells,  u ~ U(0,1),  x = F^-1(u)
% which the model implements as  find(cumsum(prior) >= u, 1).
%
% This function draws nDraws targets exactly that way and compares the
% empirical frequency of every cell with the analytical prior.  A correct
% generator differs from the prior only by sampling error, of order
% sqrt(p(1-p)/n); anything much larger means the inversion is wrong.
%
% Outputs and saves figures/fig5_prior_sampling.png.

if nargin < 1 || isempty(kind),   kind   = 'mixed'; end
if nargin < 2 || isempty(nDraws), nDraws = 20000;  end

p  = config();
sc = make_scenario(kind, p.mapSeed, p);
H  = p.H;
W  = p.W;

% --- inverse transform, identical to the line used inside simulate_once ---
cdf = cumsum(sc.prior(:));
rng(p.targetSeed, 'twister');
u   = rand(nDraws, 1);
idx = zeros(nDraws, 1);
for k = 1:nDraws
    idx(k) = find(cdf >= u(k), 1, 'first');
end

emp  = accumarray(idx, 1, [H*W 1]) / nDraws;
anal = sc.prior(:);

% --- validation metrics ----------------------------------------------------
cellSE          = sqrt(anal .* (1 - anal) / nDraws);
metrics.tv      = 0.5 * sum(abs(emp - anal));              % total variation
metrics.maxDev  = max(abs(emp - anal));                    % worst cell
metrics.seScale = sqrt(mean(anal .* (1 - anal)) / nDraws); % mean-cell SE
metrics.zMax    = max(abs(emp - anal) ./ cellSE);          % max standardized deviation

fprintf('[inverse transform] %s map, %d draws\n', kind, nDraws);
fprintf('    total-variation distance : %.5f\n', metrics.tv);
fprintf('    largest cell deviation   : %.6f\n', metrics.maxDev);
fprintf('    max cell |z|-score       : %.2f (threshold 5.00)\n', metrics.zMax);
if metrics.zMax < 5
    fprintf('    PASS: deviations are consistent with sampling noise\n');
else
    fprintf('    CHECK: deviation is larger than sampling noise\n');
end

% --- figure: analytical vs empirical --------------------------------------
fig = figure('Color', 'w', 'Position', [100 100 1000 420]);
top = max([anal; emp]);

subplot(1, 2, 1);
imagesc(reshape(anal, H, W)); axis image; colorbar; clim([0 top]);
title('Analytical prior p(x)');
xlabel('column'); ylabel('row');

subplot(1, 2, 2);
imagesc(reshape(emp, H, W)); axis image; colorbar; clim([0 top]);
title(sprintf('Inverse-transform draws (n = %d)', nDraws));
xlabel('column'); ylabel('row');

style_figure();

outPng = fullfile(fileparts(mfilename('fullpath')), 'figures', 'fig5_prior_sampling.png');
exportgraphics(fig, outPng, 'Resolution', 200);
fprintf('    saved %s\n', outPng);
end
