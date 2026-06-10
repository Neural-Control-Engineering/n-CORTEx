function DF_out = nexOp_spkComposite(DF_in, args)
% nexOp_spkComposite  Composite spike amplitudes × spatial profiles into a
% probe-space DF ready for nexObj_pixelGram.
%
% INPUTS
%   DF_in   — spk_amplitudes DF
%               .df   (n_units × n_tbins)
%               .ax.factor  unit indices
%               .ax.t       time bin values (ms)
%
%   args    — opArgs struct from cfg.opCfg.entryParams:
%               .spatial_profiles  (n_units × n_chans) normalized amplitude
%                                   fingerprint (from spk_spatial_profiles DF)
%               .output_mode       'probe' | 'rgb'  [default 'rgb']
%               .unit_hues         (n_units × 1) values in [0,1]
%                                   [default: evenly spaced, ordered by unit index]
%               .brightness_pctile scalar normalisation percentile [default 95]
%               .chan_ids           (n_chans × 1) channel labels [default 1:n_chans]
%
% OUTPUT
%   DF_out  — probe-space DF for pixelGram
%     probe mode:  .df  (n_chans × n_tbins)            — greyscale amplitude
%     rgb mode:    .df  (n_chans × n_tbins × 3)         — truecolour HSV composite
%               .ax.chans   channel labels
%               .ax.t       time bin values (carried through from input)
%
% COMPOSITING FORMULA (rgb mode)
%   unit_probe   = amp(u,t,1) .* sprof(u,1,c)            [outer product]
%   total_amp    = sum(unit_probe, 1)                     [n_tbins × n_chans]
%   weighted_hue = sum(unit_probe .* hue(u,1,1), 1) ./ (total_amp + eps)
%   brightness   = min(total_amp / prctile(total_amp, p), 1)
%   RGB          = hsv2rgb([hue, brightness, brightness])
%
% USAGE (setup once in main session)
%   sprof = dtsIO_readDF(nexon, 'spk_spatial_profiles_KS', []);
%   nexObj_pxg.cfg.opCfg = nex_generateCfgObj(@nexOp_spkComposite);
%   nexObj_pxg.cfg.opCfg.entryParams.spatial_profiles  = sprof.df;
%   nexObj_pxg.cfg.opCfg.entryParams.output_mode       = 'rgb';
%   nexObj_pxg.cfg.opCfg.entryParams.brightness_pctile = 95;

    % --- defaults ---
    output_mode       = 'rgb';
    brightness_pctile = 95;
    if isfield(args, 'output_mode'),       output_mode       = args.output_mode;       end
    if isfield(args, 'brightness_pctile'), brightness_pctile = args.brightness_pctile; end

    amp   = double(DF_in.df);           % (n_units × n_tbins)
    sprof = double(args.spatial_profiles); % (n_units × n_chans)

    [n_units, n_tbins] = size(amp);
    n_chans = size(sprof, 2);

    % default unit hues: evenly spaced
    if isfield(args, 'unit_hues') && ~isempty(args.unit_hues)
        unit_hues = args.unit_hues(:);
    else
        unit_hues = linspace(0, 1, n_units + 1)';
        unit_hues(end) = [];
    end

    % default channel IDs
    if isfield(args, 'chan_ids') && ~isempty(args.chan_ids)
        chan_ids = args.chan_ids(:)';
    else
        chan_ids = 1:n_chans;
    end

    % --- outer product: (n_units × n_tbins × n_chans) ---
    %   unit_probe(u,t,c) = amp(u,t) * sprof(u,c)
    unit_probe = reshape(amp,   n_units, n_tbins, 1) .* ...
                 reshape(sprof, n_units, 1,       n_chans);

    % --- collapsed probe: (n_tbins × n_chans) ---
    total_amp = squeeze(sum(unit_probe, 1));   % (n_tbins × n_chans)

    % --- output ---
    DF_out.ax.t     = DF_in.ax.t;
    DF_out.ax.chans = chan_ids;

    switch lower(output_mode)

        case 'probe'
            % greyscale: (n_chans × n_tbins) — matches LFP pixelGram layout
            DF_out.df = single(total_amp');    % (n_chans × n_tbins)

        case 'rgb'
            % HSV amplitude-weighted hue compositing
            weighted_hue = squeeze( ...
                sum(unit_probe .* reshape(unit_hues, n_units, 1, 1), 1) ...
            ) ./ (total_amp + eps);            % (n_tbins × n_chans)

            % brightness: clip at percentile to prevent rare large events
            % from compressing the dynamic range
            p95 = prctile(total_amp(:), brightness_pctile);
            if p95 == 0, p95 = 1; end
            brightness = min(total_amp / p95, 1);

            % HSV: hue = unit blend, saturation = brightness, value = brightness
            % -> weak signals fade to black; saturated at peak amplitude
            HSV = cat(3, weighted_hue, brightness, brightness); % (n_tbins × n_chans × 3)
            RGB = hsv2rgb(HSV);                                  % (n_tbins × n_chans × 3)

            % transpose spatial dims to match LFP layout: (n_chans × n_tbins × 3)
            DF_out.df = single(permute(RGB, [2, 1, 3]));

        otherwise
            error('nexOp_spkComposite: unknown output_mode ''%s''', output_mode);
    end
end
