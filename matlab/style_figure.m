function style_figure()
% STYLE_FIGURE  Force a light, print-friendly appearance.
%
% Recent MATLAB releases default to a dark theme: the figure background is
% black, so grey grid lines and grey labels are hard to read in a report.
% figure('Color','w') only changes the figure, not the axes.  Call this
% right before exportgraphics.

set(gcf, 'Color', 'w');

% Loop over every axes, so multi-panel figures are styled too.
axs = findobj(gcf, 'Type', 'axes');
for a = 1:numel(axs)
    ax = axs(a);
    ax.Color       = 'w';
    ax.XColor      = 'k';
    ax.YColor      = 'k';
    ax.GridColor   = [0.55 0.55 0.55];
    ax.GridAlpha   = 0.35;
    ax.FontSize    = 11;
    ax.Title.Color = 'k';
end

lg = findobj(gcf, 'Type', 'legend');
for k = 1:numel(lg)
    lg(k).Color     = 'w';
    lg(k).TextColor = 'k';
    lg(k).EdgeColor = [0.60 0.60 0.60];
end
end
