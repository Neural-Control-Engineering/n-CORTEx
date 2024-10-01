function DTS_out = batch_npxls_pmtmBands(bands, DTS)
    bandNames = fieldnames(bands);
    bandWindows = [200, 120, 60, 50, 16];
    % DTS row masking
    selDTS = DTS;
    PSD = {};
    PSD_accum = cell(1,height(selDTS));
    f_accum = cell(1,height(selDTS));
    for i = 1:length(bandNames)
        band = bandNames{i};
        bandWindow = bandWindows(i);  
        PSD_pmtm = {};
        f_pmtm = {};
        t_pmtm = {};
        PSD_label = sprintf("PSD_%s_pmtm",band);
        f_label = sprintf("f_%s_pmtm",band);
        t_label = sprintf("t_%s_pmtm",band);
        parfor j = 1:height(selDTS)            
            cfg = struct;
            cfg.windowLen = bandWindow;
            cfg.method = "pmtm";
            cfg.stride=1;
            cfg.Fs = 500;
            cfg.chanRange=1;
            cfg.eofGap = 200; % end of stft stride
            % row Sel / LFP extraction for current row
            dtRow = selDTS(j,:);
            lfp = dtRow.lfp{1};
            if ~isempty(lfp)
                if size(lfp,2) < 10000
                    [psd, freq, time] = computeSpectralDensity(cfg, lfp);
                    % store results
                    PSD_pmtm{j} = psd;
                    f_pmtm{j} = freq;
                    t_pmtm{j} = time;
                else
                    PSD_pmtm{j} = [];
                    f_pmtm{j} = [];
                    t_pmtm{j} = [];
                end
            end
        end        
        PSD_slice = cellfun(@(x, f) x(:,find((f>bands.(band)(1) & f<bands.(band)(2))),:), PSD_pmtm,f_pmtm,"UniformOutput",false);
        disp("PSD slice");
        disp(size(PSD_slice));
        disp("PSD accum");
        disp(size(PSD_accum));
        PSD_accum = cellfun(@(psdAcc ,x) cat(2,psdAcc, x), PSD_accum, PSD_slice, "UniformOutput",false);
        f_accum = cellfun(@(fAcc, f) cat(1, fAcc, f(find(f>bands.(band)(1) & f<bands.(band)(2)))),f_accum,f_pmtm,"UniformOutput",false);               
    end    
    selDTS.PSD_pmtm = PSD_accum';
    selDTS.f_pmtm = f_accum';
    selDTS.t_pmtm = t_pmtm';
    DTS_out = selDTS;
end