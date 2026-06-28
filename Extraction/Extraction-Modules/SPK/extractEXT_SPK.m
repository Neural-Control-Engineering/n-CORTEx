function SPK = extractEXT_SPK(SLRT, dataDir, session, bin_s, sigma_s, doViz)
% extractEXT_SPK  Top-level SPK extractor — mirrors extractEXT_LFP / extractEXT_AP.
%
% SPK = extractEXT_SPK(SLRT, dataDir, session)
% SPK = extractEXT_SPK(SLRT, dataDir, session, bin_s, sigma_s)
% SPK = extractEXT_SPK(SLRT, dataDir, session, bin_s, sigma_s, doViz)
%
% Iterates over sorted trigger folders for the session, calls extSPK for
% each trigger gate, and concatenates rows into a single SPK table.
%
% Output columns (one row per trial). Per sorter S in {KS, RTS}, five DFs in the
% <S>_<base>_<stub> naming consumed by nexus_exportDTS / dtsIO_composeDF:
%   S_spk_activity_df  (unit × t × measure)  + _unit, _t, _measure
%   S_spk_spatial_df   (unit × chan)         + _unit, _chans
%   S_spk_templates_df (wf × unit)           + _wf, _unit
%   S_spk_probe_df     (t × chan)            + _t, _chans
%   S_spk_units_df     (unit × factor)       + _unit, _factor  ([root_elec,loc_x,loc_y])
%   S_spk_units_quality
% See extSPK for details. Event alignment is on demand via nexOp_eventAlignDF.

    if nargin < 4 || isempty(bin_s),   bin_s   = 0.005; end
    if nargin < 5 || isempty(sigma_s), sigma_s = 0.025; end
    if nargin < 6 || isempty(doViz),   doViz   = false; end

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
        trig_spk = extSPK(SLRT, npxlsPath, trigNum, bin_s, sigma_s, doViz);

        if ~isempty(trig_spk)
            if isempty(SPK)
                SPK = trig_spk;
            else
                SPK = [SPK; trig_spk];  %#ok<AGROW>
            end
        end
    end
end
