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
PICKLE_PATH = fullfile(inter_path, 'rt_sort.pickle');
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

%% Load Python modules
disp('Loading Python modules...');
np       = py.importlib.import_module('numpy');
pickle   = py.importlib.import_module('pickle');
builtins = py.importlib.import_module('builtins');

%% Load RTSort pickle
disp('Loading pickle...');
fh  = builtins.open(PICKLE_PATH, 'rb');
obj = pickle.load(fh);
fh.close();

N_UNITS  = double(int32(obj.num_seqs));
N_CHANS  = double(int32(obj.num_elecs));
N_BEFORE = double(int32(obj.seq_n_before));
N_AFTER  = double(int32(obj.seq_n_after));
N_WF     = N_BEFORE + N_AFTER + 1;
fprintf('  %d units  |  %d channels  |  waveform window: %d samples\n', N_UNITS, N_CHANS, N_WF);

%% Spike trains
spike_list   = py.list(obj.seq_spike_trains);
spike_trains = cell(N_UNITS, 1);
for u = 1:N_UNITS
    spike_trains{u} = double(spike_list{u}.astype(np.float64));
end

%% Spatial / amplitude / latency fields
locs = double(obj.seq_locs.astype(np.float64));          % (N_UNITS x 2)  x/y um

root_elecs_list = py.list(py.getattr(obj, '_seq_root_elecs'));
root_elecs = zeros(N_UNITS, 1);
for u = 1:N_UNITS
    root_elecs(u) = double(root_elecs_list{u}) + 1;     % Python 0-indexed -> MATLAB 1-indexed
end

root_amp_means = double(obj.seqs_root_amp_means.cpu().numpy().astype(np.float64));
root_amp_stds  = double(obj.seqs_root_amp_stds.cpu().numpy().astype(np.float64));
seqs_amps      = double(obj.seqs_amps.cpu().numpy().astype(np.float64));      % (N_UNITS x N_COMP)
seqs_latencies = double(obj.seqs_latencies.cpu().numpy().astype(np.float64)); % (N_UNITS x N_COMP)
comp_elecs     = double(obj.comp_elecs_flattened.cpu().numpy().astype(np.float64)) + 1;

%% Load traces (.npy - native MATLAB reader, no Python conversion)
fprintf('Loading traces: %s\n', TRACES_PATH);
traces = loadNPY(TRACES_PATH);    % (N_CHANS x N_SAMP)
N_SAMP = size(traces, 2);
fprintf('  traces: %d x %d  (%.1f GB as single)\n', ...
    size(traces,1), size(traces,2), numel(traces)*4/1e9);

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
        raw      = traces(:, reshape(t_idx.', 1, []));                % (N_CHANS x n_valid*N_WF)
        snippets = permute(reshape(single(raw), N_CHANS, N_WF, n_valid), [3 2 1]);
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

fig_t = figure('Position', [50 50 nCols_t*120 nRows_t*80], 'Visible', 'off');
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
exportgraphics(fig_t, TEMPLATES_PLOT_PATH, 'Resolution', 150);
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
save(OUT_PATH, ...
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

exportgraphics(fig, PLOT_PATH, 'Resolution', 150);
fprintf('Plot saved -> %s\n', PLOT_PATH);

end  % extract_rtsort

% =============================================================================
%  Local functions
% =============================================================================

function data = loadNPY(filepath)
% Read a .npy file natively in MATLAB - no Python conversion for large arrays.
% Supports float16/32/64, int16/32/64, uint16; C-order and Fortran-order.
    fid = fopen(filepath, 'rb');
    fread(fid, 6, 'uint8');                          % magic \x93NUMPY
    ver_major = fread(fid, 1, 'uint8=>uint8');
    fread(fid, 1, 'uint8');                          % minor version
    if ver_major == 1
        hdr_len = fread(fid, 1, 'uint16=>double', 0, 'ieee-le');
    else
        hdr_len = fread(fid, 1, 'uint32=>double', 0, 'ieee-le');
    end
    hdr = char(fread(fid, hdr_len, 'char=>char')');

    tok   = regexp(hdr, "'descr':\s*'([^']+)'", 'tokens');
    descr = tok{1}{1};

    tok   = regexp(hdr, "'shape':\s*\(([^)]*)\)", 'tokens');
    parts = strtrim(strsplit(tok{1}{1}, ','));
    parts = parts(~cellfun('isempty', parts));
    shape = cellfun(@str2double, parts);

    tok        = regexp(hdr, "'fortran_order':\s*(True|False)", 'tokens');
    is_fortran = strcmp(tok{1}{1}, 'True');

    n_elem = prod(shape);

    switch descr
        case {'<f2','=f2','|f2'}
            raw  = fread(fid, n_elem, 'uint16=>uint16', 0, 'ieee-le');
            data = half2double(raw);
        case {'>f2'}
            raw  = fread(fid, n_elem, 'uint16=>uint16', 0, 'ieee-be');
            data = half2double(raw);
        case {'<f4','=f4'}
            data = fread(fid, n_elem, 'single=>single', 0, 'ieee-le');
        case {'>f4'}
            data = fread(fid, n_elem, 'single=>single', 0, 'ieee-be');
        case {'<f8','=f8'}
            data = fread(fid, n_elem, 'double=>double', 0, 'ieee-le');
        case {'>f8'}
            data = fread(fid, n_elem, 'double=>double', 0, 'ieee-be');
        case {'<i2','=i2'}, data = fread(fid, n_elem, 'int16=>int16',  0, 'ieee-le');
        case {'<i4','=i4'}, data = fread(fid, n_elem, 'int32=>int32',  0, 'ieee-le');
        case {'<i8','=i8'}, data = fread(fid, n_elem, 'int64=>int64',  0, 'ieee-le');
        case {'<u2','=u2'}, data = fread(fid, n_elem, 'uint16=>uint16',0, 'ieee-le');
        otherwise
            fclose(fid);
            error('loadNPY: unsupported dtype ''%s''', descr);
    end
    fclose(fid);

    if numel(shape) > 1
        if ~is_fortran
            data = reshape(data, fliplr(shape));
            data = permute(data, numel(shape):-1:1);
        else
            data = reshape(data, shape);
        end
    end
end

function d = half2double(u)
% IEEE 754 half-precision uint16 -> double
    u = uint16(u);
    s = double(bitshift(u, -15));
    e = double(bitand(bitshift(u, -10), uint16(31)));
    m = double(bitand(u, uint16(1023)));
    d = zeros(size(u), 'double');
    n_mask       = (e > 0) & (e < 31);
    d(n_mask)    = (1 - 2*s(n_mask)) .* 2.^(e(n_mask)-15) .* (1 + m(n_mask)/1024);
    sb_mask      = (e == 0) & (m ~= 0);
    d(sb_mask)   = (1 - 2*s(sb_mask)) .* 2^(-14) .* (m(sb_mask)/1024);
    inf_mask     = (e == 31) & (m == 0);
    d(inf_mask)  = (1 - 2*s(inf_mask)) .* Inf;
    d((e==31) & (m~=0)) = NaN;
end
