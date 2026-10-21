function Tglobal = build_globalSignalTable(T)
% build_globalSignalTable  Cross-channel average per (subject, condition,
% trial, band, t) -- the shared/common-signal estimate for the
% global-confound diagnostic (Nexus WIP.md MixedEffect notes). Averaging
% across chans cancels out each channel's own idiosyncratic local
% variation and leaves mostly whatever's common to the whole recording at
% that moment.
%
% Step 1/2 of the diagnostic: run build_bandHierarchy directly on
% Tglobal (it already has subject/condition/bandPower + band/t grid
% columns, same shape build_bandHierarchy expects) to test whether the
% shared signal ITSELF is significantly related to condition -- a single
% test per (band,t) cell, not 540, since chans has already been collapsed
% out.
%
%   T       : output of build_bandPowerRegionTable (must include 'trial')
%
%   Tglobal : table, one row per (subject,condition,trial,band,t), with
%             bandPower = mean across chans for that cell.

    if ~ismember('trial', T.Properties.VariableNames)
        error('build_globalSignalTable:noTrial', ...
            ['T has no ''trial'' column -- rebuild it with the current ' ...
             'build_bandPowerRegionTable (trial is now always included).']);
    end
    if ~ismember('chans', T.Properties.VariableNames)
        error('build_globalSignalTable:noChans', ...
            'T has no ''chans'' column -- nothing to average across.');
    end

    keyVars = setdiff(T.Properties.VariableNames, {'chans', 'bandPower'}, 'stable');
    [idx, keys] = findgroups(T(:, keyVars));
    Tglobal = keys;
    Tglobal.bandPower = splitapply(@mean, T.bandPower, idx);
    nChans = numel(categories(T.chans));
    fprintf('[build_globalSignalTable] %d rows -> %d (subject,condition,trial,band,t) cells (mean over %d chans)\n', ...
        height(T), height(Tglobal), nChans);
end
