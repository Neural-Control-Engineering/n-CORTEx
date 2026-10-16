function [specs, kernel_args, psd_fit] = specParam_multiExp(f_psd, df_psd, args, df_cf)
% df_cf (optional): caller-supplied segment-boundary corner frequencies —
% same shape psdIO_readCornerFrequencies itself returns (real detected
% corners only, NOT including f_psd(end) — that's still appended below
% either way). When supplied, corner AUTO-detection and the near-line-
% noise (55-65 Hz) push-away are both skipped entirely: the caller is
% asserting these boundaries are already deliberate (e.g. nexObj_
% fitScope's Fit_pe reusing the current FC2/FC3 from an existing
% aperiodic fit to re-segment for a peaks-only re-fit — FC1 itself is
% just fRange_start, not a real corner, see spcpmIO_multiSpecs2vector).

    % CFG HEADER
    peakWidth_min = args.peakWidth_min; % default = 4
    peakWidth_max = args.peakWidth_max; % default = 8  
    numPeaks_max = args.numPeaks_max; % default = 8
    peakHeight_min = args.peakHeight_min; % default = 0.1    
    peakThreshold = args.peakThreshold; % default = 0.5
    chanRange_start  = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384
    fRange_start = args.fRange_start; % default = 2
    fRange_end = args.fRange_end; % default = 50
    doPlot = isfield(args, 'doPlot') && args.doPlot;

    % translate params
    peak_width_limits = py.tuple([args.peakWidth_min, args.peakWidth_max]);
    max_n_peaks = py.int(args.numPeaks_max);
    min_peak_height = py.int(args.peakHeight_min);
    peak_threshold = py.int(args.peakThreshold);

    if nargin < 4 || isempty(df_cf)
        % locate corner frequencies
        df_cf = psdIO_readCornerFrequencies(f_psd, df_psd);
        % push cornerfrequencies away from line freq (60 Hz)
        lineFreqCond = (df_cf>55)&(df_cf<65);
        % df_cf(lineFreqCond)=df_cf(lineFreqCond)+20;
        df_cf(lineFreqCond)=65;
    end
    df_cf = [df_cf, f_psd(end)];
    specParam = py.importlib.import_module('specparam');               
    mode_PE='gaussian';
    mode_AP='fixed';
    fg = specParam.SpectralModel(pyargs( ...
      'peak_width_limits', peak_width_limits, ...
      'max_n_peaks',       max_n_peaks, ...
      'min_peak_height',   min_peak_height, ...
      'peak_threshold',    peak_threshold, ...
      'aperiodic_mode',    mode_AP, ...
      'periodic_mode',     mode_PE));
    
    SPEC = [];
    SEG = {};
    tol_Hz = 0;
    f_all=[];
    psd_all=[];
    psd_fit_all=[];
    clear specs
    % split/fit (specParam)
    for i = 1:length(df_cf)
        % if i==length(df_cf)
        %     f_end = f_psd(end);
        % else
        %     f_end = df_cf(i);        
        % end
        f_end = df_cf(i)-tol_Hz;        
        if i==1
            f_start = fRange_start;                        
        else
            f_start = df_cf(i-1)+tol_Hz;            
        end
        fCond = (f_psd>=f_start)&(f_psd<=f_end);
        psd_i = df_psd(fCond);
        % A degenerate segment (f_start beyond the data's actual range —
        % e.g. a caller-supplied corner frequency, like fitPeriodic's own
        % FC2/FC3 reuse, landing past f_psd(end)) selects zero points here.
        % Python's specparam errors opaquely ("Inputs are not the right
        % dimensions") on an empty fit — skip the fit and fill zeros
        % instead of crashing; SPEC still gets a row so the caller's
        % fixed-3-segment assumption (spcpmIO_multiSpecs2vector/
        % spcpmIO_specs2kernel) isn't broken.
        if sum(fCond) < 3
            warning(['specParam_multiExp: segment %d [%.2f, %.2f] Hz has too ' ...
                     'few samples (%d) to fit — filling zeros for this segment.'], ...
                    i, f_start, f_end, sum(fCond));
            specs_out = zeros(1, 2 + numPeaks_max*3);
            psd_fit   = zeros(1, numel(psd_i));
        else
            f_i = py.numpy.array(f_psd(fCond));
            psd_i_deLog = py.numpy.array(10.^((psd_i)/10));
            fg.fit(f_i,psd_i_deLog);
            % specs = fg.results.params;
            specs.aperiodic_params=fg.results.params.aperiodic;
            specs.periodic_params=fg.results.params.periodic;
            specs.metrics=fg.results.metrics;
            [specs_out, scores] = formatSpecParamOutputs(specs, args);
            % specs_out(2) = fitEXP_segment(f_psd(fCond), psd_i, specs_out);
            psd_fit      = spec2psd(f_psd(fCond), specs_out, 'fixed', 'gaussian');
        end
        f_all = [f_all, f_psd(fCond)];
        psd_all = [psd_all, psd_i];
        psd_fit_all = [psd_fit_all, psd_fit];
        specs_out = [specs_out, f_start];
        SPEC = [SPEC; specs_out];
        SEG = [SEG; f_psd(fCond)];
    end
    if doPlot
        figure; loglog(f_all, psd_all); hold on; loglog(f_all, 10*psd_fit_all);
        ylim([-190,-70]);
    end
    % RESULTS
    psd_fit = psd_fit_all;
    % vectorize output (OFF1, OFF2, ..., EXP1, EXP2, ..., PK1(1:3), ...
    specs = spcpmIO_multiSpecs2vector(SPEC);
    % convert to kernel args
    kernel_args = spcpmIO_specs2kernel(specs);
    % kernel_args.OFF=SPEC(1,1);
    % % kernel_args.EXP1=SPEC(1,2);
    % % kernel_args.EXP2=SPEC(2,2);
    % % kernel_args.EXP3=SPEC(3,2);
    % kernel_args.EXP1=1;
    % kernel_args.EXP2=7;
    % kernel_args.EXP3=49;
    % consolidate into lorentzian form
    % ax.f = f_psd;
    % psd_fit = kernel_specparam_segmented_multiexp(ax, kernel_args);
    % figure; loglog(f_psd,10*log10(abs(10.^psd_fit)))
    % figure; loglog(f_psd,(psd_fit));
    % hold on; loglog(f_psd,df_psd)
end


% ─────────────────────────────────────────────────────────────────────────────
function EXP_opt = fitEXP_segment(f_seg, psd_dB, specs)
    f_seg = f_seg(:);
    pk = zeros(size(f_seg));
    for ip = 3:3:numel(specs)
        pk = pk + specs(ip+1) * exp(-(f_seg - specs(ip)).^2 / (2*specs(ip+2)^2));
    end
    EXP_opt = max(0, log10(max(f_seg, 1e-10)) \ (specs(1) + pk - psd_dB(:)/10));
end

    % % PERIODIC COMPONENTS (Gaussian Peaks)
    % % infer number of peaks
    % cfFields = fieldnames(args);
    % cfFields = cfFields(contains(cfFields,'CF'));
    % numCF =(regexp(cfFields,'\d+','match'));
    % numCF = cellfun(@(cf) str2double(cf), numCF, "UniformOutput", true);
    % % fit = 10*log10(abs(10.^(fit_AP+OFF)));
    % fit = fit_AP;
    % for j=numCF'
    % 
    %     CFID = sprintf("CF%d",j);
    %     PWID = sprintf("PW%d",j);
    %     BWID = sprintf("BW%d",j);
    % 
    %     CF = args.(CFID);
    %     PW = args.(PWID);
    %     BW = args.(BWID);
    % 
    %     fit_PE  = PW  * exp(-(f_spec - CF ).^2 / (2 * BW^2));
    %     fit = fit + (fit_PE);
    % end
