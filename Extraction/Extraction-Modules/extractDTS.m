function extractDTS(params)
    sessionsToExtract = params.extrctItms.DTS.sessionsToExtract;
    sessions          = sessionsToExtract.sessions;
    extData           = params.paths.Data.EXT;
    dtsPath           = params.paths.Data.DTS.local;
    extractionLog     = params.extrctItms.DTS.extractionLog;
    logPath           = fullfile(params.paths.projDir_cloud, "Experiments", ...
                            params.extractCfg.experiment, "Extraction-Logs", ...
                            "DTS_extraction_log.csv");

    [h5File, manifest] = nexDTS_openOrCreate(dtsPath);

    extFields = fieldnames(extData);
    % ignore the top-level local/cloud directory fields
    % dirMask   = ~cellfun(@(x) strcmp(x,"local") || strcmp(x,"cloud"), extFields);
    % extFields = extFields(dirMask);
    extFields = ["SLRT"; fieldnames(params.extrctItms.EXT.extrctModules)];

    for i = 1:length(sessions)
        session = sessions{i};
        dts     = [];

        % horizontal join across modalities for this session
        modPassed = [];
        for j = 1:length(extFields)
            extField = extFields(j);
            disp(extField);
            if ~sessionExists(params, session, extField, "EXT"), continue; end

            try
                sessionFile = sprintf("%s.mat", session);
                DT = load(fullfile(extData.(extField).cloud, sessionFile));
                dtField = fieldnames(DT);
                DT = DT.(dtField{1});

                % standardized column names (camelback convention)
                DT = normalizeAddressCols(DT);
                % modality-specific legacy renames (old on-disk data)
                DT = normalizeModalityCols(DT, extField);

                if iscell(DT.trialNumber)
                    DT.trialNumber = cell2mat(DT.trialNumber);
                end

                if isempty(dts)
                    dts = DT;
                elseif ~isempty(DT)
                    dts = outerjoin(dts, DT, "Keys", {'sessionLabel','trialNumber'}, ...
                                    "MergeKeys", true);
                end
                modPassed(end+1) = 1;
            catch e
                fprintf("WARNING: skipping %s / %s — %s\n", session, extField, e.message);
                modPassed(end+1) = 0;
                continue;
            end
        end

        if isempty(dts)
            fprintf("WARNING: no data found for session %s\n", session);
            continue;
        end

        if iscell(dts.trialNumber)
            dts.trialNumber = cell2mat(dts.trialNumber);
        end

        rowsBefore = height(manifest);
        manifest   = nexDTS_appendRows(dts, h5File, manifest);

        % Log session as extracted only if rows were actually written
        if height(manifest) <= rowsBefore
            fprintf("WARNING: no new rows written for session %s (already present or empty)\n", session);
        end
        if isfile(logPath) && height(manifest) > rowsBefore && all(modPassed)
            extractionLog = readtable(logPath);
            extractionLog(contains(extractionLog.SessionName, session), :).Extracted = 1;
            writetable(extractionLog, logPath);
        end
        save(fullfile(dtsPath, 'nexDTS_manifest.mat'), 'manifest');
        % assignin("base", "DTS", manifest);

    end

    % save(fullfile(dtsPath, 'nexDTS_manifest.mat'), 'manifest');
    assignin("base", "DTS", manifest);
end

% ── Local helper ──────────────────────────────────────────────────────────

function DT = normalizeModalityCols(DT, modality)
% Rename legacy per-modality column names to the current dfID_<stub> convention.
    vars = DT.Properties.VariableNames;
    switch upper(char(modality))
        case 'LFP'
            % lfp → lfp_df,  t_lfp → lfp_t  (extLFP now writes the new names;
            % these renames cover existing on-disk extractions)
            if ismember('lfp',   vars), DT = renamevars(DT, 'lfp',   'lfp_df'); end
            if ismember('t_lfp', vars), DT = renamevars(DT, 't_lfp', 'lfp_t');  end
    end
end

function DT = normalizeAddressCols(DT)
% Rename legacy address column variants to camelback convention.
    renames = {'trial_number','trialNumber'; 'trial_num','trialNumber'; ...
               'trialNum','trialNumber';     'session_label','sessionLabel'};
    vars = DT.Properties.VariableNames;
    for k = 1:size(renames,1)
        if ismember(renames{k,1}, vars)
            DT = renamevars(DT, renames{k,1}, renames{k,2});
        end
    end
end
