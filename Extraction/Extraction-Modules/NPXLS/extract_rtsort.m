function extract_rtsort(inter_path)
% extract_rtsort(inter_path)
% Loads RTSort output files written by extractRAW_rtSort, extracts waveforms,
% computes quality metrics, generates summary plots, and saves rtsort_results.mat.
%
% inter_path - directory containing rt_sort.pickle and scaled_traces.npy

%% CONFIG
if ispc
    inter_path = strrep(inter_path, '~', getenv('USERPROFILE'));
else
    inter_path = strrep(inter_path, '~', getenv('HOME'));
end
TRACES_PATH = fullfile(inter_path, 'scaled_traces.npy');
OUT_PATH    = fullfile(inter_path, 'rtsort_results.mat');
PLOT_PATH   = fullfile(inter_path, 'rtsort_quality.png');

RAW_SAMP_FREQ = 30000;   % Hz - adjust if not 30 kHz
REFRAC_MS     = 2;     % refractory period (ms)
REFRAC_SAMP   = REFRAC_MS * 1e-3 * RAW_SAMP_FREQ;  % 45 samples

ISI_GOOD = 0.005;  ISI_MUA = 0.05;   % ISI violation rate thresholds
CV_GOOD  = 0.30;   CV_MUA  = 0.50;   % amplitude CV thresholds
CNT_GOOD = 50;     CNT_MUA = 20;     % minimum spike count thresholds

COLORS = struct('good',  [0.18 0.80 0.44], ...
                'mua',   [0.95 0.61 0.07], ...
                'noise', [0.91 0.29 0.24]);

%% Load RTSort fields  (exported by runRTSort.py as a plain .mat - no embedded Python)
% The RT-Sort pickle holds torch tensors, so it can only be unpickled where
% torch is importable. runRTSort.py does that in its clean subprocess and dumps
% the needed fields here; we read them natively to avoid embedding torch in
% MATLAB (which collides with MATLAB's libexpat.dll in-process).
disp('Loading RTSort fields...');
FIELDS_PATH = fullfile(inter_path, 'rtsort_fields.mat');
F = load(FIELDS_PATH);

N_UNITS  = double(F.num_seqs);
N_CHANS  = double(F.num_elecs);
N_BEFORE = double(F.seq_n_before);
N_AFTER  = double(F.seq_n_after);
N_WF     = N_BEFORE + N_AFTER + 1;
fprintf('  %d units  |  %d channels  |  waveform window: %d samples\n', N_UNITS, N_CHANS, N_WF);

%% Spike trains
spike_trains = cell(N_UNITS, 1);
for u = 1:N_UNITS
    spike_trains{u} = double(F.seq_spike_trains{u});
end

%% Spatial / amplitude / latency fields
locs = double(F.seq_locs);                               % (N_UNITS x 2)  x/y um
root_elecs = double(F.seq_root_elecs(:)) + 1;            % Python 0-indexed -> MATLAB 1-indexed
root_amp_means = double(F.seqs_root_amp_means);
root_amp_stds  = double(F.seqs_root_amp_stds);
seqs_amps      = double(F.seqs_amps);                    % (N_UNITS x N_COMP)
seqs_latencies = double(F.seqs_latencies);               % (N_UNITS x N_COMP)
comp_elecs     = double(F.comp_elecs_flattened) + 1;

%% Memory-map traces (.npy) -- read only the snippet windows we need.
% A full recording can be enormous (1 h @ 30 kHz x 384 ch ~ 83 GB float16,
% 166 GB as single), so materializing the whole array is infeasible AND wasteful:
% we only ever read N_WF-sample windows around each spike. Memory-map the file and
% gather just those samples -- reads scale with (#spikes x N_WF), not recording
% length, keeping peak RAM at a few hundred MB regardless of duration.
fprintf('Memory-mapping traces: %s\n', TRACES_PATH);
[tmap, N_CHANS_T, N_SAMP, halfToSingle] = openNPY_map(TRACES_PATH);  % tmap.Data.x is (N_SAMP x N_CHANS)
if N_CHANS_T ~= N_CHANS
    error('extract_rtsort:chanMismatch', ...
        'traces span %d channels but fields report %d', N_CHANS_T, N_CHANS);
end
fprintf('  traces: %d chans x %d samples (memory-mapped, float16 on disk)\n', N_CHANS_T, N_SAMP);

%% 1. Waveform extraction
disp('Extracting waveforms...');
mean_templates = zeros(N_UNITS, N_WF, N_CHANS, 'single');
spike_amps_all = cell(N_UNITS, 1);

for u = 1:N_UNITS
    st      = spike_trains{u};
    root_ch = root_elecs(u);
    st_samp = st * RAW_SAMP_FREQ / 1000;          % ms -> samples
    valid   = (st_samp >= N_BEFORE + 1) & (st_samp <= N_SAMP - N_AFTER);
    st_v    = round(st_samp(valid));
    n_valid = numel(st_v);
    amps_all = NaN(numel(st), 1);

    if n_valid > 0
        % t_idx (n_valid x N_WF): sample index for every timepoint of every spike
        t_idx    = bsxfun(@plus, st_v(:), (-N_BEFORE : N_AFTER));
        rows     = reshape(t_idx.', [], 1);                          % (n_valid*N_WF x 1), window-fastest
        rawU     = tmap.Data.x(rows, :);                             % (n_valid*N_WF x N_CHANS): only these samples read
        snippets = permute(reshape(halfToSingle(rawU), N_WF, n_valid, N_CHANS), [2 1 3]);
        %  -> (n_valid x N_WF x N_CHANS)

        mean_templates(u, :, :) = mean(snippets, 1);

        root_wf    = squeeze(snippets(:, :, root_ch));                 % (n_valid x N_WF)
        if n_valid == 1, root_wf = root_wf(:)'; end                   % guard scalar squeeze
        amps_valid = max(root_wf, [], 2) - min(root_wf, [], 2);
        amps_all(valid) = amps_valid;
    end

    spike_amps_all{u} = amps_all;
    if mod(u, 20) == 0
        fprintf('  %d/%d units\n', u, N_UNITS);
    end
end
fprintf('  done - templates: %d x %d x %d\n', size(mean_templates));

%% 2. Quality assessment
% ISI violation rate:
%   Count ISIs below the refractory period; rate = n_violations / n_spikes.
%
% Amplitude CV (std/mean):
%   From per-spike peak-to-trough amplitudes; falls back to model aggregate.
%
% Classification (noise checked first):
%   noise : n_spikes < CNT_MUA  OR  ISI_viol > ISI_MUA  OR  CV > CV_MUA
%   mua   : ISI_viol > ISI_GOOD OR  CV > CV_GOOD         OR  n_spikes < CNT_GOOD
%   good  : everything else

disp('Computing quality metrics...');
isi_viol_rates = zeros(N_UNITS, 1);
amp_cvs        = zeros(N_UNITS, 1);
spike_counts   = cellfun(@numel, spike_trains);
quality_labels = cell(N_UNITS, 1);

for u = 1:N_UNITS
    st = spike_trains{u};
    n  = spike_counts(u);

    if n > 1
        isis   = diff(sort(st));          % ISIs in ms
        n_viol = sum(isis < REFRAC_MS);
        isi_viol_rates(u) = n_viol / n;
    end

    amps       = spike_amps_all{u};
    valid_amps = amps(~isnan(amps));
    if numel(valid_amps) > 1
        amp_cvs(u) = std(valid_amps) / (mean(valid_amps) + 1e-9);
    else
        amp_cvs(u) = root_amp_stds(u) / (root_amp_means(u) + 1e-9);
    end

    iv = isi_viol_rates(u);
    cv = amp_cvs(u);
    if n < CNT_MUA || iv > ISI_MUA || cv > CV_MUA
        quality_labels{u} = 'noise';
    elseif iv > ISI_GOOD || cv > CV_GOOD || n < CNT_GOOD
        quality_labels{u} = 'mua';
    else
        quality_labels{u} = 'good';
    end
end

n_good  = sum(strcmp(quality_labels, 'good'));
n_mua   = sum(strcmp(quality_labels, 'mua'));
n_noise = sum(strcmp(quality_labels, 'noise'));
fprintf('  Quality: %d good | %d mua | %d noise\n', n_good, n_mua, n_noise);
fprintf('  u##  label  spikes  ISI_viol  amp_CV\n');
for u = 1:N_UNITS
    fprintf('  u%02d  %-5s  %5d   %.4f    %.3f\n', ...
        u, quality_labels{u}, spike_counts(u), isi_viol_rates(u), amp_cvs(u));
end

%% Template overview plot (coloured by quality)
nCols_t = ceil(sqrt(N_UNITS));
nRows_t = ceil(N_UNITS / nCols_t);
t_wf_ax = (-N_BEFORE : N_AFTER);

all_wf = zeros(N_UNITS, N_WF);
for u = 1:N_UNITS
    all_wf(u,:) = double(mean_templates(u, :, root_elecs(u)));
end
ylims = [min(all_wf(:)), max(all_wf(:))];
if diff(ylims) == 0, ylims = ylims + [-1 1]; end

fig_t = figure('Position', [50 50 nCols_t*120 nRows_t*80], 'Visible', 'off', ...
               'Color', 'k', 'DefaultAxesColor', 'k');   % dark mode; boxes stay class-coloured
tiledlayout(nRows_t, nCols_t, 'TileSpacing', 'none', 'Padding', 'compact');

for u = 1:N_UNITS
    ax = nexttile;
    clr = COLORS.(quality_labels{u});
    plot(t_wf_ax, all_wf(u,:), 'Color', clr, 'LineWidth', 1.0);
    xlim([t_wf_ax(1) t_wf_ax(end)]);
    ylim(ylims);
    set(ax, 'XTick',[], 'YTick',[], 'Box','on', 'XColor', clr, 'YColor', clr);
    text(0.05, 0.85, num2str(u), 'Units','normalized', ...
         'FontSize', 6, 'Color', clr);
end

TEMPLATES_PLOT_PATH = fullfile(inter_path, 'rtsort_templates.png');
exportgraphics(fig_t, TEMPLATES_PLOT_PATH, 'Resolution', 150, 'BackgroundColor', 'current');
fprintf('Templates plot saved -> %s\n', TEMPLATES_PLOT_PATH);

%% Save .mat
disp('Saving .mat...');
max_spk         = max(spike_counts);
spike_train_mat = NaN(max_spk, N_UNITS);
spike_amp_mat   = NaN(max_spk, N_UNITS);
for u = 1:N_UNITS
    n = spike_counts(u);
    spike_train_mat(1:n, u) = spike_trains{u};
    a = spike_amps_all{u};
    spike_amp_mat(1:numel(a), u) = a;
end

N_CHANS = size(mean_templates, 3);
save(strcat("\\?\", OUT_PATH), ...   % \\?\ = Windows long-path prefix (v7.3 save fails on >260-char paths)
    'N_UNITS','N_CHANS','RAW_SAMP_FREQ','N_BEFORE','N_AFTER','REFRAC_MS', ...
    'spike_train_mat','spike_counts','spike_amp_mat', ...
    'locs','root_elecs','comp_elecs', ...
    'seqs_amps','seqs_latencies','root_amp_means','root_amp_stds', ...
    'mean_templates','quality_labels','isi_viol_rates','amp_cvs', ...
    '-v7.3');
fprintf('Saved -> %s\n', OUT_PATH);

%% Plots
fig = figure('Position', [50 50 1400 900], 'Visible', 'off');
tl  = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact'); %#ok<NASGU>
lbls    = quality_labels;
classes = {'good','mua','noise'};

% Panel A - quality metric space
nexttile;
for ci = 1:3
    cls  = classes{ci};
    mask = strcmp(lbls, cls);
    scatter(isi_viol_rates(mask)*100, amp_cvs(mask), ...
            spike_counts(mask)*0.8 + 10, COLORS.(cls), ...
            'filled', 'MarkerEdgeColor','k','LineWidth',0.3, ...
            'DisplayName', cls);
    hold on;
end
xline(ISI_GOOD*100, '--', 'Color',[.5 .5 .5], 'LineWidth',0.8);
xline(ISI_MUA*100,  ':',  'Color',[.5 .5 .5], 'LineWidth',0.8);
yline(CV_GOOD, '--', 'Color',[.5 .5 .5], 'LineWidth',0.8);
yline(CV_MUA,  ':',  'Color',[.5 .5 .5], 'LineWidth',0.8);
set(gca, 'XScale','linear');
xlabel('ISI violation rate (%)');
ylabel('Amplitude CV');
title('A  Quality metric space  (size prop spike count)');
legend('Location','northeast','FontSize',7);

% Panel B - probe spatial map
nexttile;
for ci = 1:3
    cls  = classes{ci};
    mask = strcmp(lbls, cls);
    scatter(locs(mask,1), locs(mask,2), 60, COLORS.(cls), ...
            'filled', 'MarkerEdgeColor','k','LineWidth',0.3, ...
            'DisplayName', cls);
    hold on;
end
for u = 1:N_UNITS
    text(locs(u,1), locs(u,2), num2str(u), ...
        'FontSize',5,'HorizontalAlignment','center','Color','k');
end
set(gca,'YDir','reverse');
xlabel('x (um)');  ylabel('y (um)');
title('B  Probe map');
legend('Location','best','FontSize',7);

% Panel C - spike counts, ranked
nexttile;
[~, sort_idx] = sort(spike_counts, 'descend');
bar_colors    = zeros(N_UNITS, 3);
for u = 1:N_UNITS
    bar_colors(u,:) = COLORS.(quality_labels{sort_idx(u)});
end
b = bar(1:N_UNITS, spike_counts(sort_idx), 1.0, 'EdgeColor','none');
b.FaceColor = 'flat';
b.CData     = bar_colors;
yline(CNT_GOOD, '--', 'Color',[.5 .5 .5], 'LineWidth',0.8);
yline(CNT_MUA,  ':',  'Color',[.5 .5 .5], 'LineWidth',0.8);
xlabel('Unit rank (by spike count)');  ylabel('Spike count');
title('C  Spike counts');

% Panel D - amplitude over time (drift)
nexttile;
for u = 1:N_UNITS
    st   = spike_trains{u};
    amps = spike_amps_all{u};
    ok   = ~isnan(amps);
    if sum(ok) < 2, continue; end
    scatter(st(ok)/1000, amps(ok), 1, COLORS.(quality_labels{u}), ...
            'filled', 'MarkerFaceAlpha',0.3);
    hold on;
end
xlabel('Time (s)');  ylabel('Spike amplitude (a.u.)');
title('D  Amplitude over time (drift/stability)');

% Panel E - mean waveforms on root channel
nexttile;
t_wf   = (-N_BEFORE : N_AFTER);
offset = 0;
N_EX   = 4;
for ci = 1:3
    cls   = classes{ci};
    idxs  = find(strcmp(lbls, cls));
    idxs  = idxs(1:min(N_EX, numel(idxs)));
    for u = idxs(:)'
        wf = squeeze(mean_templates(u, :, root_elecs(u)));
        plot(t_wf, double(wf) + offset, 'Color', COLORS.(cls), 'LineWidth',0.9);
        hold on;
        offset = offset + max(range(double(wf)), 5) * 1.5;
    end
end
xline(0, ':', 'Color','k','LineWidth',0.6);
xlabel('Samples relative to spike');
ylabel('Amplitude (offset per unit)');
title(sprintf('E  Mean waveforms (root ch, %d per class)', N_EX));
line(NaN,NaN,'Color',COLORS.good, 'DisplayName','good');
line(NaN,NaN,'Color',COLORS.mua,  'DisplayName','mua');
line(NaN,NaN,'Color',COLORS.noise,'DisplayName','noise');
legend('Location','best','FontSize',7);

% Panel F - ISI distributions by class
nexttile;
bin_edges = linspace(0, 100, 60);
for ci = 1:3
    cls      = classes{ci};
    all_isis = [];
    for u = find(strcmp(lbls, cls))'
        st = spike_trains{u};
        if numel(st) > 1
            isis_ms = diff(sort(st(:)));          % already in ms
            all_isis = [all_isis; isis_ms(isis_ms < 100)]; %#ok<AGROW>
        end
    end
    if ~isempty(all_isis)
        histogram(all_isis, bin_edges, 'Normalization','probability', ...
                  'FaceColor',COLORS.(cls),'FaceAlpha',0.55,'EdgeColor','none', ...
                  'DisplayName',sprintf('%s (n=%d)',cls,numel(all_isis)));
        hold on;
    end
end
xline(REFRAC_MS, '--', 'Color','k','LineWidth',0.8, 'DisplayName', ...
      sprintf('refractory (%.1f ms)', REFRAC_MS));
xlabel('ISI (ms)');  ylabel('Probability');
title('F  ISI distributions by class');
legend('Location','northeast','FontSize',7);

applyDarkMode(fig);
exportgraphics(fig, PLOT_PATH, 'Resolution', 150, 'BackgroundColor', 'current');
fprintf('Plot saved -> %s\n', PLOT_PATH);

%% Additional validation views (raster + spatial/depth fingerprint)
% Supplementary, so guard them: a plotting hiccup must not fail the extraction
% (rtsort_results.mat is already saved above). Meant for eyeballing consistency
% within and across sessions.
try
    dur_s   = N_SAMP / RAW_SAMP_FREQ;
    fr_hz   = spike_counts(:) / dur_s;              % per-unit firing rate (Hz), column
    depth   = locs(:, 2);                           % probe y (um), column
    ramp    = root_amp_means(:);                    % root amplitude, column (shape-safe for scatter)
    [~, depth_order] = sort(depth, 'ascend');
    classes = {'good','mua','noise'};

    % ---- Raster + population rate (rtsort_raster.png) ----
    RASTER_PATH = fullfile(inter_path, 'rtsort_raster.png');
    fig_r = figure('Position', [50 50 1500 950], 'Visible', 'off');
    tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax_pop = nexttile;                              % population rate strip
    bin_s = 1.0;
    edges = 0 : bin_s : max(dur_s, bin_s);
    all_s = cell2mat(cellfun(@(st) st(:)/1000, spike_trains, 'UniformOutput', false));
    pop   = histcounts(all_s, edges) / bin_s;
    plot(edges(1:end-1) + bin_s/2, pop, 'k', 'LineWidth', 0.9);
    ylabel('pop (Hz)'); xlim([0 dur_s]); set(ax_pop, 'XTickLabel', []);
    title(sprintf('Population rate  (%d units, %.0f s, %d total spikes)', ...
        N_UNITS, dur_s, sum(spike_counts)));

    ax_r = nexttile([3 1]); hold(ax_r, 'on');       % raster, depth-ordered
    for r = 1:N_UNITS
        u  = depth_order(r);
        st = spike_trains{u} / 1000;                % s
        if isempty(st), continue; end
        plot(ax_r, st, r*ones(numel(st),1), '.', ...
            'Color', COLORS.(quality_labels{u}), 'MarkerSize', 2);
    end
    xlabel('Time (s)'); ylabel('Unit (sorted by probe depth)');
    xlim([0 dur_s]); ylim([0 N_UNITS+1]);
    title('Spike raster   (green good / orange mua / red noise)');
    applyDarkMode(fig_r);
    exportgraphics(fig_r, RASTER_PATH, 'Resolution', 150, 'BackgroundColor', 'current'); close(fig_r);
    fprintf('Raster saved -> %s\n', RASTER_PATH);

    % ---- Spatial / depth fingerprint (rtsort_spatial.png) ----
    SPATIAL_PATH = fullfile(inter_path, 'rtsort_spatial.png');
    fig_s = figure('Position', [50 50 1500 950], 'Visible', 'off');
    tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    nbins = max(10, round(N_UNITS/3));

    nexttile; hold on;                              % A: probe map, size ~ rate
    for ci = 1:3
        m = strcmp(quality_labels, classes{ci});
        scatter(locs(m,1), locs(m,2), 12 + 40*fr_hz(m)/max(fr_hz+eps), ...
            COLORS.(classes{ci}), 'filled', 'MarkerEdgeColor','k', ...
            'LineWidth',0.3, 'DisplayName',classes{ci});
    end
    set(gca,'YDir','reverse'); xlabel('x (um)'); ylabel('depth y (um)');
    title('A  Probe map (size \propto rate)'); legend('FontSize',7,'Location','best');

    nexttile; hold on;                              % B: depth vs firing rate
    for ci = 1:3
        m = strcmp(quality_labels, classes{ci});
        scatter(fr_hz(m), depth(m), 30, COLORS.(classes{ci}), 'filled', ...
            'MarkerEdgeColor','k','LineWidth',0.3);
    end
    set(gca,'YDir','reverse'); xlabel('firing rate (Hz)'); ylabel('depth y (um)');
    title('B  Depth vs rate');

    nexttile; hold on;                              % C: depth vs root amplitude
    for ci = 1:3
        m = strcmp(quality_labels, classes{ci});
        scatter(ramp(m), depth(m), 30, COLORS.(classes{ci}), 'filled', ...
            'MarkerEdgeColor','k','LineWidth',0.3);
    end
    set(gca,'YDir','reverse'); xlabel('root amplitude (a.u.)'); ylabel('depth y (um)');
    title('C  Depth vs amplitude');

    nexttile;                                       % D: rate distribution
    histogram(fr_hz, nbins, 'FaceColor',[.4 .4 .4], 'EdgeColor','none');
    xlabel('firing rate (Hz)'); ylabel('# units'); title('D  Rate distribution');

    nexttile;                                       % E: units along probe
    histogram(depth, nbins, 'Orientation','horizontal', ...
        'FaceColor',[.4 .4 .4], 'EdgeColor','none');
    set(gca,'YDir','reverse'); ylabel('depth y (um)'); xlabel('# units');
    title('E  Units along probe');

    nexttile;                                       % F: amplitude distribution
    histogram(ramp, nbins, 'FaceColor',[.4 .4 .4], 'EdgeColor','none');
    xlabel('root amplitude (a.u.)'); ylabel('# units'); title('F  Amplitude distribution');

    applyDarkMode(fig_s);
    exportgraphics(fig_s, SPATIAL_PATH, 'Resolution', 150, 'BackgroundColor', 'current'); close(fig_s);
    fprintf('Spatial fingerprint saved -> %s\n', SPATIAL_PATH);
catch ME
    warning('extract_rtsort:vizFailed', 'Supplementary plots failed: %s', ME.message);
end

end  % extract_rtsort

% =============================================================================
%  Local functions
% =============================================================================

function applyDarkMode(fig)
% Recolour a figure for dark mode: black background, white axes/labels/titles,
% and flip only pure-black traces/markers/reference-lines/text to white so they
% stay visible. Class-coloured elements (COLORS.*) and grey guides are untouched.
    W = [1 1 1];
    set(fig, 'Color', 'k');
    for a = findall(fig, 'Type', 'axes')'
        set(a, 'Color', 'k', 'XColor', W, 'YColor', W, 'ZColor', W, ...
               'GridColor', [.8 .8 .8], 'MinorGridColor', [.6 .6 .6]);
        set([a.Title a.XLabel a.YLabel a.ZLabel], 'Color', W);
    end
    for l = findall(fig, 'Type', 'legend')'
        set(l, 'Color', 'k', 'TextColor', W, 'EdgeColor', W);
    end
    for ln = findall(fig, 'Type', 'line')'
        if isequal(ln.Color, [0 0 0]), set(ln, 'Color', W); end
    end
    for cl = findall(fig, 'Type', 'constantline')'          % xline/yline
        if isequal(cl.Color, [0 0 0]), set(cl, 'Color', W); end
    end
    for t = findall(fig, 'Type', 'text')'
        if isequal(t.Color, [0 0 0]), set(t, 'Color', W); end
    end
    for s = findall(fig, 'Type', 'scatter')'
        if isequal(s.MarkerEdgeColor, [0 0 0]), set(s, 'MarkerEdgeColor', W); end
    end
end

function [mm, nChan, nSamp, convFn] = openNPY_map(filepath)
% Memory-map a 2-D (channels x samples) .npy so callers read arbitrary sample
% windows without loading the whole array. Returns:
%   mm     - memmapfile; mm.Data.x is an (nSamp x nChan) view (the transpose of
%            the on-disk channels x samples layout -- see note below), so
%            mm.Data.x(sampleRows, :) gathers all channels at those samples.
%   nChan, nSamp - dimensions from the .npy header.
%   convFn - converts a raw slice to single (half->single for float16 files;
%            identity/cast for single/double).
% Only C-order (fortran_order False) is supported -- numpy's np.save default.

    % memmapfile cannot open >260-char Windows paths and does not accept the
    % \\?\ prefix (fopen below tolerates the long path, but memmapfile does not).
    % Convert to the 8.3 short path so the OS map succeeds.
    if ispc
        fp = char(filepath);
        [st, sp] = system(['for %I in ("' fp '") do @echo %~sI']);
        sp = strtrim(sp);
        if st == 0 && ~isempty(sp) && exist(sp, 'file') == 2
            filepath = sp;
        end
    end

    fid = fopen(filepath, 'rb');
    if fid < 0, error('openNPY_map: cannot open %s', filepath); end
    fread(fid, 6, 'uint8');                          % magic \x93NUMPY
    ver_major = fread(fid, 1, 'uint8=>uint8');
    fread(fid, 1, 'uint8');                          % minor version
    if ver_major == 1
        hdr_len  = fread(fid, 1, 'uint16=>double', 0, 'ieee-le');
        preamble = 10;                               % 6 magic + 1 maj + 1 min + 2 len
    else
        hdr_len  = fread(fid, 1, 'uint32=>double', 0, 'ieee-le');
        preamble = 12;                               % 6 + 1 + 1 + 4 len
    end
    hdr = char(fread(fid, hdr_len, 'char=>char')');
    fclose(fid);
    data_offset = preamble + hdr_len;                % bytes to first data element

    tok = regexp(hdr, "'descr':\s*'([^']+)'", 'tokens');            descr = tok{1}{1};
    tok = regexp(hdr, "'fortran_order':\s*(True|False)", 'tokens');
    if strcmp(tok{1}{1}, 'True')
        error('openNPY_map: fortran-order .npy not supported (%s)', filepath);
    end
    tok   = regexp(hdr, "'shape':\s*\(([^)]*)\)", 'tokens');
    parts = strtrim(strsplit(tok{1}{1}, ','));
    parts = parts(~cellfun('isempty', parts));
    shape = cellfun(@str2double, parts);
    if numel(shape) ~= 2
        error('openNPY_map: expected a 2-D array, got %d-D', numel(shape));
    end
    nChan = shape(1);  nSamp = shape(2);             % npy shape = (chans, samples)

    switch descr
        case {'<f2','=f2','|f2'}, fmt = 'uint16'; convFn = @half2single;
        case {'<f4','=f4'},       fmt = 'single'; convFn = @(x) x;
        case {'<f8','=f8'},       fmt = 'double'; convFn = @(x) single(x);
        otherwise
            error('openNPY_map: unsupported dtype ''%s'' (expected float16/32/64)', descr);
    end

    % C-order (chans, samples) flat buffer read column-major as (nSamp x nChan):
    % on-disk element [c,s] sits at c*nSamp + s, i.e. MATLAB (s+1, c+1) of an
    % [nSamp x nChan] matrix. So x(:,c) is channel c's trace and x(rows,:) gathers
    % all channels at the requested samples, touching only those rows on disk.
    mm = memmapfile(filepath, 'Offset', data_offset, ...
                    'Format', {fmt, [nSamp nChan], 'x'}, 'Writable', false);
end

function d = half2single(u)
% IEEE 754 half-precision uint16 -> single (single-precision temporaries only)
    u = uint16(u);
    s = single(bitshift(u, -15));
    e = single(bitand(bitshift(u, -10), uint16(31)));
    m = single(bitand(u, uint16(1023)));
    d = zeros(size(u), 'single');
    n_mask       = (e > 0) & (e < 31);
    d(n_mask)    = (1 - 2*s(n_mask)) .* 2.^(e(n_mask)-15) .* (1 + m(n_mask)/1024);
    sb_mask      = (e == 0) & (m ~= 0);
    d(sb_mask)   = (1 - 2*s(sb_mask)) .* single(2^(-14)) .* (m(sb_mask)/1024);
    inf_mask     = (e == 31) & (m == 0);
    d(inf_mask)  = (1 - 2*s(inf_mask)) .* single(Inf);
    d((e==31) & (m~=0)) = single(NaN);
end
