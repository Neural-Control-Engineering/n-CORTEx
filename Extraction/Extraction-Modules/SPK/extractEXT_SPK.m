function SPK = extractEXT_SPK(SLRT, dataDir, session, bin_ms, sigma_ms)
% extractEXT_SPK  Top-level SPK extractor — mirrors extractEXT_LFP / extractEXT_AP.
%
% SPK = extractEXT_SPK(SLRT, dataDir, session)
% SPK = extractEXT_SPK(SLRT, dataDir, session, bin_ms, sigma_ms)
%
% Iterates over sorted trigger folders for the session, calls extSPK for
% each trigger gate, and concatenates rows into a single SPK table.
%
% Output columns (sorter-parallel, one row per trial):
%   trial_num, session_label
%   spk_raster_KS / _RTS,  spk_rates_KS / _RTS
%   spk_amplitudes_KS / _RTS,  spk_spatial_profiles_KS / _RTS
%   spk_templates_KS / _RTS,  spk_probe_KS / _RTS
%   t_bins_KS / _RTS
%   <event>_aligned_t_bins_KS / _RTS  (one pair per event signal)

    if nargin < 4 || isempty(bin_ms),   bin_ms   = 5;  end
    if nargin < 5 || isempty(sigma_ms), sigma_ms = 25; end

    imecPath   = fullfile(dataDir.RAW.NPXLS.cloud, session, sprintf('%s_imec0', session));
    imecDir    = dir(imecPath);
    sortedTrigs = struct2table(imecDir);
    sortedTrigs = sortedTrigs.name;
    sortedTrigs = sortedTrigs(contains(sortedTrigs, 'sorted'));
    numTrigs    = size(sortedTrigs, 1);

    SPK = [];
    for j = 1:numTrigs
        sortedFldr = sortedTrigs{j};
        if ispc
            npxlsPath = fullfile(strcat('\\?\', imecPath), sortedFldr);
        else
            npxlsPath = fullfile(imecPath, sortedFldr);
        end
        expmntLabel = strrep(string(sortedTrigs{j}), '_sorted', '');
        [trigNum, ~] = decodeTrigger(expmntLabel);
        trigNum = trigNum + 1;  % decodeTrigger returns 0-indexed

        fprintf('extractEXT_SPK: processing trigger %d (%s)\n', trigNum, sortedFldr);
        trig_spk = extSPK(SLRT, npxlsPath, trigNum, bin_ms, sigma_ms);

        if ~isempty(trig_spk)
            if isempty(SPK)
                SPK = trig_spk;
            else
                SPK = [SPK; trig_spk];  %#ok<AGROW>
            end
        end
    end
end
