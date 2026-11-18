function search_app()
% SEARCH_APP  Select, animate and analyse drone search missions.

p = config();
bg = [0.95 0.96 0.96];
ink = [0.12 0.18 0.21];
muted = [0.34 0.40 0.42];
accent = [0.08 0.35 0.38];
terrainColors = [0.85 0.92 0.75; 0.45 0.68 0.45; 0.72 0.72 0.72; 0.60 0.78 0.92];
priorContour = [];
playbackDelay = 0.03;
fig = figure('Name', 'Drone Search & Rescue', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Color', bg, ...
    'Position', [100 100 1200 730]);

label(fig, 'Drone search & rescue', [0.035 0.92 0.6 0.045], 19, ink, 'bold');
label(fig, 'Set up a mission, watch the search, and review its outcome.', ...
    [0.035 0.885 0.7 0.03], 10, muted, 'normal');
panel = uipanel(fig, 'Title', ' Mission setup ', 'FontSize', 11, 'FontWeight', 'bold', ...
    'ForegroundColor', ink, 'BackgroundColor', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.035 0.34 0.245 0.52]);
label(panel, 'Terrain', [0.08 0.86 0.84 0.07], 10, ink, 'bold');
terrain = uicontrol(panel, 'Style', 'popupmenu', 'String', {'Mixed', 'Open', 'Forest', 'Urban'}, ...
    'Units', 'normalized', 'Position', [0.08 0.78 0.84 0.08], 'FontSize', 11, 'Callback', @preview);
label(panel, 'Search strategy', [0.08 0.68 0.84 0.07], 10, ink, 'bold');
strategy = uicontrol(panel, 'Style', 'popupmenu', ...
    'String', {'Parallel track', 'Probability-based', 'Random walk'}, ...
    'Units', 'normalized', 'Position', [0.08 0.60 0.84 0.08], 'FontSize', 11);
label(panel, 'Drones (1–20)', [0.08 0.50 0.40 0.07], 10, ink, 'bold');
fleet = uicontrol(panel, 'Style', 'edit', 'String', '5', 'Units', 'normalized', ...
    'Position', [0.08 0.42 0.38 0.08], 'BackgroundColor', 'white', 'FontSize', 11);
label(panel, 'People (1–5)', [0.54 0.50 0.38 0.07], 10, ink, 'bold');
people = uicontrol(panel, 'Style', 'edit', 'String', '1', 'Units', 'normalized', ...
    'Position', [0.54 0.42 0.38 0.08], 'BackgroundColor', 'white', 'FontSize', 11);
label(panel, 'Playback delay / step (seconds)', [0.08 0.32 0.84 0.07], 10, ink, 'bold');
speed = uicontrol(panel, 'Style', 'edit', 'String', '0.03', 'Units', 'normalized', ...
    'Position', [0.08 0.24 0.84 0.08], 'BackgroundColor', 'white', 'FontSize', 11, ...
    'Callback', @change_speed, 'TooltipString', 'Smaller values play faster. Change during playback.');
label(panel, 'Random seed', [0.08 0.14 0.55 0.07], 10, ink, 'bold');
seed = uicontrol(panel, 'Style', 'edit', 'String', num2str(p.targetSeed), 'Units', 'normalized', ...
    'Position', [0.08 0.05 0.52 0.08], 'BackgroundColor', 'white', 'FontSize', 11);
newSeed = uicontrol(panel, 'Style', 'pushbutton', 'String', 'New seed', ...
    'Units', 'normalized', 'Position', [0.63 0.05 0.29 0.08], 'Callback', @fresh_seed);

runButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Run animated mission', ...
    'Units', 'normalized', 'Position', [0.035 0.275 0.245 0.05], ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', accent, ...
    'ForegroundColor', 'white', 'Callback', @run_mission);
label(fig, 'Analysis runs', [0.035 0.226 0.12 0.03], 10, ink, 'bold');
runs = uicontrol(fig, 'Style', 'edit', 'String', '400', 'Units', 'normalized', ...
    'Position', [0.17 0.225 0.11 0.035], 'BackgroundColor', 'white', 'FontSize', 10);
analysisButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Run statistical analysis', ...
    'Units', 'normalized', 'Position', [0.035 0.16 0.245 0.05], ...
    'FontSize', 11, 'Callback', @run_analysis);
pauseButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Pause', ...
    'Units', 'normalized', 'Position', [0.035 0.105 0.117 0.04], ...
    'Enable', 'off', 'Callback', @toggle_pause);
stopButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Stop', ...
    'Units', 'normalized', 'Position', [0.163 0.105 0.117 0.04], ...
    'Enable', 'off', 'Callback', @stop_run);
status = label(fig, 'Ready', [0.035 0.045 0.26 0.045], 10, muted, 'normal');

ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.325 0.34 0.40 0.48]);
resultPanel = uipanel(fig, 'Title', ' Results ', 'FontSize', 11, 'FontWeight', 'bold', ...
    'ForegroundColor', ink, 'BackgroundColor', 'white', 'Units', 'normalized', ...
    'Position', [0.755 0.18 0.215 0.68]);
label(resultPanel, 'Animated mission', [0.05 0.91 0.90 0.06], 11, ink, 'bold');
missionTable = uitable(resultPanel, 'Units', 'normalized', 'Position', [0.05 0.68 0.90 0.23], ...
    'ColumnName', {'Measure', 'Result'}, 'RowName', [], 'ColumnWidth', {'auto', 'auto'}, ...
    'FontSize', 10, 'Data', {'Status', 'Not run'; 'People found', '—'; 'Time to find all', '—'; 'Coverage', '—'});
missionSettings = label(resultPanel, 'Choose settings and run a mission.', ...
    [0.05 0.53 0.90 0.14], 9, muted, 'normal');
label(resultPanel, 'Statistical analysis', [0.05 0.46 0.90 0.06], 11, ink, 'bold');
analysisTable = uitable(resultPanel, 'Units', 'normalized', 'Position', [0.05 0.15 0.90 0.31], ...
    'ColumnName', {'Measure', 'Result'}, 'RowName', [], 'ColumnWidth', {'auto', 'auto'}, ...
    'FontSize', 10, 'Data', {'Status', 'Not run'; 'All found', '—'; '95% interval', '—'; ...
    'Mean found', '—'; 'Mean coverage', '—'; 'Missions', '—'});
analysisSettings = label(resultPanel, 'Run an analysis to estimate performance.', ...
    [0.05 0.01 0.90 0.13], 9, muted, 'normal');
priorToggle = uicontrol(fig, 'Style', 'checkbox', 'String', 'Show target-likelihood contours', ...
    'Value', 1, 'Units', 'normalized', 'Position', [0.325 0.285 0.36 0.035], ...
    'BackgroundColor', bg, 'ForegroundColor', ink, 'FontSize', 10, 'Callback', @toggle_prior, ...
    'TooltipString', 'Red contours show likely areas, not the people themselves.');
label(fig, 'MAP KEY', [0.325 0.235 0.10 0.03], 9, muted, 'bold');
keyPositions = [0.325 0.199; 0.425 0.199; 0.525 0.199; 0.625 0.199];
keyNames = {'Open', 'Forest', 'Urban', 'Water'};
for i = 1:numel(keyNames)
    uicontrol(fig, 'Style', 'text', 'String', '', 'Units', 'normalized', ...
        'Position', [keyPositions(i, 1) keyPositions(i, 2) 0.015 0.022], ...
        'BackgroundColor', terrainColors(i, :));
    label(fig, keyNames{i}, [keyPositions(i, 1)+0.019 keyPositions(i, 2)-0.002 0.075 0.03], 9, ink, 'normal');
end
label(fig, 'Blue circle: drone     Yellow star: base     Red: not found     Green: found', ...
    [0.325 0.155 0.58 0.03], 10, ink, 'normal');
label(fig, 'Shaded cells: searched     Red contours: likely target locations', ...
    [0.325 0.115 0.63 0.03], 10, ink, 'normal');
label(fig, 'Missions continue after detection to measure full coverage.', ...
    [0.325 0.075 0.63 0.03], 10, muted, 'normal');
preview();

    function preview(~, ~)
        kinds = {'mixed', 'open', 'forest', 'urban'};
        sc = make_scenario(kinds{get(terrain, 'Value')}, p.mapSeed, p);
        draw_map(sc);
        title(ax, 'Ready to search');
    end

    function draw_map(sc)
        cla(ax);
        imagesc(ax, sc.terrain);
        colormap(ax, terrainColors);
        caxis(ax, [0.5 4.5]);
        axis(ax, 'image');
        hold(ax, 'on');
        [~, priorContour] = contour(ax, sc.prior, 4, 'LineColor', [0.75 0.15 0.15], 'LineWidth', 1);
        toggle_prior();
        xlabel(ax, 'Cell column');
        ylabel(ax, 'Cell row');
    end

    function toggle_prior(~, ~)
        if ~isempty(priorContour) && isgraphics(priorContour)
            if get(priorToggle, 'Value'), visible = 'on'; else, visible = 'off'; end
            set(priorContour, 'Visible', visible);
        end
    end

    function change_speed(~, ~)
        value = str2double(get(speed, 'String'));
        if ~isfinite(value) || value < 0
            set(speed, 'String', num2str(playbackDelay));
            set(status, 'String', 'Speed unchanged: enter a nonnegative delay.');
        else
            playbackDelay = value;
        end
    end

    function fresh_seed(~, ~)
        rng('shuffle');
        set(seed, 'String', sprintf('%.0f', randi(2^31 - 1)));
    end

    function [sc, strat, n, seedValue, delay, count, description, nPeople] = settings()
        kinds = {'mixed', 'open', 'forest', 'urban'};
        strategies = {'parallel', 'prior', 'random'};
        names = {'Parallel track', 'Probability-based', 'Random walk'};
        kind = kinds{get(terrain, 'Value')};
        strat = strategies{get(strategy, 'Value')};
        n = str2double(get(fleet, 'String'));
        nPeople = str2double(get(people, 'String'));
        seedValue = str2double(get(seed, 'String'));
        delay = str2double(get(speed, 'String'));
        count = str2double(get(runs, 'String'));
        if ~isfinite(n) || n ~= fix(n) || n < 1 || n > p.nMax
            error('Enter a whole number of drones between 1 and %d.', p.nMax);
        end
        if ~isfinite(nPeople) || nPeople ~= fix(nPeople) || nPeople < 1 || nPeople > 5
            error('Enter a whole number of people between 1 and 5.');
        end
        if ~isfinite(seedValue) || seedValue ~= fix(seedValue) || seedValue < 0 || seedValue > 2^32 - 1
            error('Enter a whole-number seed between 0 and 4294967295.');
        end
        if ~isfinite(delay) || delay < 0
            error('Enter a nonnegative playback delay in seconds.');
        end
        if ~isfinite(count) || count ~= fix(count) || count < 1 || count > 100000
            error('Enter a whole number of analysis runs between 1 and 100000.');
        end
        sc = make_scenario(kind, p.mapSeed, p);
        rng(seedValue, 'twister');
        description = sprintf('Terrain: %s\n%s\n%d drones / %d people\nSeed: %.0f', ...
            kind, names{get(strategy, 'Value')}, n, nPeople, seedValue);
    end

    function set_busy(busy, isPlayback)
        if nargin < 2, isPlayback = false; end
        if busy, state = 'off'; stopState = 'on'; else, state = 'on'; stopState = 'off'; end
        set([terrain, strategy, fleet, people, speed, seed, newSeed, runs, runButton, analysisButton], 'Enable', state);
        set(stopButton, 'Enable', stopState);
        if busy && isPlayback
            set([speed, pauseButton], 'Enable', 'on');
        else
            set(pauseButton, 'Enable', 'off');
        end
        set(pauseButton, 'String', 'Pause');
        setappdata(fig, 'stopRequested', false);
        setappdata(fig, 'paused', false);
    end

    function stop_run(~, ~)
        setappdata(fig, 'stopRequested', true);
        set(status, 'String', 'Stopping...');
    end

    function toggle_pause(~, ~)
        paused = ~getappdata(fig, 'paused');
        setappdata(fig, 'paused', paused);
        if paused
            set(pauseButton, 'String', 'Resume');
            set(status, 'String', 'Playback paused.');
        else
            set(pauseButton, 'String', 'Pause');
            set(status, 'String', 'Playback resumed.');
        end
    end

    function run_mission(~, ~)
        try
            [sc, strat, n, ~, delay, ~, description, nPeople] = settings();
            playbackDelay = delay;
            set_busy(true, true);
            set(missionTable, 'Data', {'Status', 'Playing'; 'People found', '—'; 'Time to find all', '—'; 'Coverage', '—'});
            set(missionSettings, 'String', description);
            set(status, 'String', 'Simulating mission...'); drawnow;
            if ~isgraphics(fig), return; end
            [res, trace] = simulate_once(sc, strat, n, p, [], nPeople);
            draw_map(sc);
            shade = imagesc(ax, zeros(p.H, p.W, 3));
            set(shade, 'AlphaData', zeros(p.H, p.W));
            plot(ax, p.base(2), p.base(1), 'p', 'MarkerSize', 12, ...
                'MarkerFaceColor', [0.95 0.85 0.2], 'MarkerEdgeColor', 'k');
            drones = plot(ax, NaN, NaN, 'o', 'MarkerSize', 8, 'LineStyle', 'none', ...
                'MarkerFaceColor', [0.1 0.35 0.9], 'MarkerEdgeColor', 'w');
            undiscovered = plot(ax, trace.targets(:, 2), trace.targets(:, 1), 'p', ...
                'MarkerSize', 15, 'MarkerFaceColor', [0.85 0.12 0.12], ...
                'MarkerEdgeColor', 'k', 'LineStyle', 'none');
            discovered = plot(ax, NaN, NaN, 'p', 'MarkerSize', 10, ...
                'MarkerFaceColor', [0.08 0.65 0.25], 'MarkerEdgeColor', 'k', 'LineStyle', 'none');
            visited = false(p.H, p.W);
            for t = 1:p.tMax
                if ~isgraphics(fig), return; end
                while getappdata(fig, 'paused') && ~getappdata(fig, 'stopRequested')
                    pause(0.05);
                    if ~isgraphics(fig), return; end
                    drawnow;
                    if ~isgraphics(fig), return; end
                end
                if getappdata(fig, 'stopRequested'), break; end
                visited(sub2ind([p.H p.W], trace.rows(t, :), trace.cols(t, :))) = true;
                set(shade, 'AlphaData', 0.22 * double(visited));
                set(drones, 'XData', trace.cols(t, :), 'YData', trace.rows(t, :));
                foundNow = ~isnan(res.timesFound) & res.timesFound <= t;
                set(undiscovered, 'XData', trace.targets(~foundNow, 2), 'YData', trace.targets(~foundNow, 1));
                set(discovered, 'XData', trace.targets(foundNow, 2), 'YData', trace.targets(foundNow, 1));
                state = sprintf('Found %d / %d', sum(foundNow), nPeople);
                title(ax, sprintf('%.1f / %.0f min  |  %s', t*p.dt/60, p.tMax*p.dt/60, state));
                drawnow;
                if ~isgraphics(fig), return; end
                if playbackDelay > 0, pause(playbackDelay); end
            end
            if ~isgraphics(fig), return; end
            if getappdata(fig, 'stopRequested')
                set(missionTable, 'Data', {'Status', 'Stopped early'; 'People found', '—'; 'Time to find all', '—'; 'Coverage', '—'});
                set(status, 'String', 'Playback stopped.');
            else
                if res.found
                    outcome = 'All found';
                    timeResult = sprintf('%.1f min', res.tFound*p.dt/60);
                else
                    outcome = 'Not all found';
                    timeResult = 'Not reached';
                end
                title(ax, sprintf('%.0f / %.0f min  |  Mission complete', p.tMax*p.dt/60, p.tMax*p.dt/60));
                set(missionTable, 'Data', {'Status', outcome; ...
                    'People found', sprintf('%d / %d', res.foundCount, nPeople); ...
                    'Time to find all', timeResult; 'Coverage', sprintf('%.1f%%', 100*res.coverage)});
                set(status, 'String', 'Mission complete.');
            end
            set_busy(false);
        catch err
            show_error(err);
        end
    end

    function run_analysis(~, ~)
        try
            [sc, strat, n, ~, ~, count, description, nPeople] = settings();
            set_busy(true);
            set(analysisTable, 'Data', {'Status', 'Running'; 'All found', '—'; '95% interval', '—'; ...
                'Mean found', '—'; 'Mean coverage', '—'; 'Missions', sprintf('0 / %d', count)});
            set(analysisSettings, 'String', description);
            hits = 0; coverage = 0; peopleFound = 0; completed = 0;
            for k = 1:count
                if ~isgraphics(fig), return; end
                if getappdata(fig, 'stopRequested'), break; end
                res = simulate_once(sc, strat, n, p, [], nPeople);
                hits = hits + res.found;
                coverage = coverage + res.coverage;
                peopleFound = peopleFound + res.foundCount;
                completed = k;
                if mod(k, max(1, ceil(count/100))) == 0 || k == count
                    set(status, 'String', sprintf('Analysis: %d / %d missions', k, count));
                    drawnow;
                end
            end
            if ~isgraphics(fig), return; end
            if getappdata(fig, 'stopRequested')
                set(analysisTable, 'Data', {'Status', 'Stopped early'; 'All found', '—'; '95% interval', '—'; ...
                    'Mean found', '—'; 'Mean coverage', '—'; 'Missions', sprintf('%d / %d', completed, count)});
                set(status, 'String', 'Analysis stopped.');
            else
                [prob, ~, lo, hi] = wilson_ci(hits, count);
                set(analysisTable, 'Data', {'Status', 'Complete'; ...
                    'All found', sprintf('%.1f%% (%d / %d)', 100*prob, hits, count); ...
                    '95% interval', sprintf('%.1f–%.1f%%', 100*lo, 100*hi); ...
                    'Mean found', sprintf('%.1f / %d', peopleFound/count, nPeople); ...
                    'Mean coverage', sprintf('%.1f%%', 100*coverage/count); ...
                    'Missions', sprintf('%d', count)});
                set(status, 'String', 'Analysis complete.');
            end
            set_busy(false);
        catch err
            show_error(err);
        end
    end

    function show_error(err)
        if ~isgraphics(fig), return; end
        set_busy(false);
        set(status, 'String', 'Unable to run. Check the inputs.');
        errordlg(err.message, 'Unable to run');
    end
end

function h = label(parent, text, position, fontSize, color, weight)
if strcmp(get(parent, 'Type'), 'figure')
    background = get(parent, 'Color');
else
    background = get(parent, 'BackgroundColor');
end
h = uicontrol(parent, 'Style', 'text', 'String', text, 'Units', 'normalized', ...
    'Position', position, 'HorizontalAlignment', 'left', 'FontSize', fontSize, ...
    'FontWeight', weight, 'ForegroundColor', color, 'BackgroundColor', background);
end
