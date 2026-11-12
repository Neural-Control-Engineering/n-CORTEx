% Visual audit for nexOp_commonMode on a synthetic 384-ch probe with KNOWN parts:
%   shared  : EMG-like broadband burst at t=0, identical on ALL channels
%   local   : 40 Hz oscillation on ch 100-130 only (should SURVIVE removal)
%   gradient: 6 Hz theta whose amplitude grows with depth (only its median part is removed)
addpath(genpath('/home/user/Code_Repo/n-CORTEx/utils/Nexus'));
rng(0); nC = 384; Fs = 500; t = -1.5:1/Fs:1.5-1/Fs; T = numel(t);
emgCarrier = filter(1, [1 -0.3], randn(1, T));                   % broadband
shared   = 40 * exp(-(t/0.06).^2) .* emgCarrier / std(emgCarrier);
local    = zeros(nC, T); local(100:130, :) = repmat(4*sin(2*pi*40*t), 31, 1);
gradient = (linspace(0, 6, nC)') .* sin(2*pi*6*t);
X = randn(nC, T) + shared + local + gradient;

DF.df = X; DF.ax.t = t; DF.ax.chans = 1:nC;
cfg = extractMethodCfg('nexOp_commonMode');                        % CFG HEADER parses?
a = cfg; a.outMode = 1; R = nexOp_commonMode(DF, a);
a.outMode = 2;          C = nexOp_commonMode(DF, a);

% ── numeric checks ───────────────────────────────────────────────────────
i0 = abs(t) < 0.06; iPre = t < -0.5;
chk.cfgFields      = strjoin(string(fieldnames(cfg))', ',');
chk.sizeRemoved    = mat2str(size(R.df));
chk.sizeCM         = mat2str(size(C.df));
chk.burstRMS_ch300 = [rms(X(300,i0)), rms(R.df(300,i0))];
chk.local40_ch115  = [rms(X(115,iPre) - gradient(115,iPre)), rms(R.df(115,iPre) - (gradient(115,iPre) - median(gradient(:,iPre),1)))];
chk.cmVsShared_r   = corr(C.df(i0)', shared(i0)');
disp(chk)

% ── PMTM compatibility: 100 ms windows on both outputs ──────────────────
% rtPMTM_magnitude_roll slices chanRange, then rtPMTM_magnitude slices it AGAIN
% on the sub-block -- so pre-slice ch100-130 and pass chanRange 1:31.
pa = struct('windowLen', 50, 'stride', 10, 'chanRange_start', 1, 'chanRange_end', 31, ...
            'Fs', Fs, 'preBuffLen', 1.5);
sub = @(D) struct('df', D.df(100:130, :), 'ax', struct('t', D.ax.t, 'chans', 100:130));
P_raw = rtPMTM_magnitude_roll(sub(DF), pa);
P_cmr = rtPMTM_magnitude_roll(sub(R),  pa);
pc = pa; pc.chanRange_start = 1; pc.chanRange_end = 1;
P_cm  = rtPMTM_magnitude_roll(C,  pc);
fprintf('PMTM sizes raw %s | cmr %s | cm %s\n', mat2str(size(P_raw.df)), mat2str(size(P_cmr.df)), mat2str(size(P_cm.df)));

% ── figure ────────────────────────────────────────────────────────────────
f = figure('Color', 'w', 'Position', [50 50 1500 900]);
tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'nexOp\_commonMode audit (synthetic probe: shared burst @0 | local 40 Hz ch100–130 | depth-graded 6 Hz)');
clim_ = [-15 15];

ax = nexttile; imagesc(t, 1:nC, X, clim_); axis xy; colormap(ax, parula);
title('1. Raw LFP'); xlabel('t (s)'); ylabel('channel'); colorbar;

ax = nexttile; imagesc(t, 1:nC, R.df, clim_); axis xy; colormap(ax, parula);
title('2. CM removed (outMode=1)'); xlabel('t (s)'); colorbar;

ax = nexttile; hold on;
plot(t, shared, 'Color', [0.7 0.7 0.7], 'LineWidth', 2.5, 'DisplayName', 'true shared burst');
plot(t, C.df, 'Color', [0.165 0.47 0.84], 'LineWidth', 1, 'DisplayName', 'CM trace (outMode=2)');
xlim([-0.4 0.4]); title(sprintf('3. CM trace vs truth (r = %.3f in burst)', chk.cmVsShared_r));
xlabel('t (s)'); legend('Box', 'off', 'Location', 'southwest'); box off;

ax = nexttile; hold on;
plot(1:nC, rms(X(:, i0), 2), 'Color', [0.92 0.41 0.20], 'LineWidth', 1.5, 'DisplayName', 'raw');
plot(1:nC, rms(R.df(:, i0), 2), 'Color', [0.165 0.47 0.84], 'LineWidth', 1.5, 'DisplayName', 'CM removed');
xregion(100, 130, 'FaceColor', [0.5 0.5 0.5], 'FaceAlpha', 0.12, 'HandleVisibility', 'off');
title('4. RMS during burst (|t|<60 ms) by channel'); xlabel('channel'); ylabel('RMS');
legend('Box', 'off'); box off;

ax = nexttile; hold on;
[px, fx] = pwelch(X(115, iPre), 256, 128, 512, Fs);
[pr, ~ ] = pwelch(R.df(115, iPre), 256, 128, 512, Fs);
plot(fx, 10*log10(px), 'Color', [0.92 0.41 0.20], 'LineWidth', 1.5, 'DisplayName', 'raw');
plot(fx, 10*log10(pr), 'Color', [0.165 0.47 0.84], 'LineWidth', 1.5, 'DisplayName', 'CM removed');
xline(40, ':', '40 Hz local', 'HandleVisibility', 'off'); xline(6, ':', '6 Hz', 'HandleVisibility', 'off');
xlim([0 100]); title('5. Ch 115 spectrum, pre-burst: local 40 Hz kept');
xlabel('Hz'); ylabel('dB'); legend('Box', 'off'); box off;

ax = nexttile;
fi = P_raw.ax.f <= 100;
gRaw = squeeze(mean(P_raw.df(:, P_raw.ax.f >= 30 & P_raw.ax.f <= 80, :), [1 2]));
gCmr = squeeze(mean(P_cmr.df(:, P_cmr.ax.f >= 30 & P_cmr.ax.f <= 80, :), [1 2]));
gCm  = squeeze(mean(P_cm.df(:,  P_cm.ax.f  >= 30 & P_cm.ax.f  <= 80, :), [1 2]));
hold on;
plot(P_raw.ax.t, gRaw, 'Color', [0.92 0.41 0.20], 'LineWidth', 1.5, 'DisplayName', 'raw (ch100–130)');
plot(P_cmr.ax.t, gCmr, 'Color', [0.165 0.47 0.84], 'LineWidth', 1.5, 'DisplayName', 'CM removed (ch100–130)');
plot(P_cm.ax.t,  gCm,  'Color', [0.11 0.69 0.48], 'LineWidth', 1.5, 'DisplayName', 'CM trace');
xline(0, ':', 'HandleVisibility', 'off');
title('6. rtPMTM 100 ms: 30–80 Hz (dB)'); xlabel('window center t (s)'); ylabel('dB');
legend('Box', 'off', 'Location', 'northwest'); box off;

exportgraphics(f, 'audit_commonMode.png', 'Resolution', 110);
