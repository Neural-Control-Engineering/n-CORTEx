function  nexInit_registry(nexon)
    categories_sessionLabel = nexOp_listCategories_sessionLabel(nexon);
    % itemize each category
    %% SESSION LABEL
    for i = 1:length(categories_sessionLabel)
        sessionLabelKey = categories_sessionLabel(i);
        sessionLabelKey_parts = split(sessionLabelKey,"--");
        sessionLabelKey_part = sessionLabelKey_parts(end);
        items = parseSessionLabelUnique(nexon.console.BASE.DTS.sessionLabel, sessionLabelKey_part);
        nexon.console.BASE.registry.categories.(strrep(sessionLabelKey_part,"--","_")) = items;
    end
    %% SIGNAL TYPES
    if isfield(nexon.console.BASE.DTS,"signal_types")
        categories_signalTypes = nexOp_listCategories_signals(nexon);
        for i = 1:length(categories_signalTypes)
            signalKey = categories_signalTypes(i);
            signalKey_parts = split(signalKey,"--");
            signalKey_part = signalKey_parts(end);
            try
                signalVals = unique(nexon.console.BASE.DTS.(signalKey_part));
            catch
                dfCol = dtsIO_readTFH5(nexon.console.BASE.DTS, signalKey_part, [],'simple');
                dfCol = cat(1,dfCol{:});
                signalVals = unique(dfCol);
            end
            nexon.console.BASE.registry.categories.(signalKey_part) = signalVals;
        end
    end
    %% LUT — color lookup tables (label → hex color), one per sessionLabel category.
    %       Accessible as nexon.console.BASE.registry.LUT.(categoryKey), e.g.
    %       registry.LUT.sessionLabel_phase.  Each LUT is a table with columns
    %       {'label', 'color'} (hex string 'RRGGBB').
    %
    %       sessionLabel_phase reuses the colors already generated in
    %       nexPanel_BASE.map_phase so the two sources stay in sync.
    for i = 1:length(categories_sessionLabel)
        sessionLabelKey       = categories_sessionLabel(i);
        sessionLabelKey_parts = split(sessionLabelKey, "--");
        sessionLabelKey_part  = sessionLabelKey_parts(end);
        fieldKey              = strrep(sessionLabelKey, "--", "_");   % e.g. "sessionLabel_phase"

        if strcmp(fieldKey, 'sessionLabel_phase') ...
                && ~isempty(nexon.console.BASE.map_phase)
            % Reuse the already-generated phase LUT to keep colors consistent
            src = nexon.console.BASE.map_phase;
            lut = table(src.phase, src.color, 'VariableNames', {'label', 'color'});
        else
            items = parseSessionLabelUnique(nexon.console.BASE.DTS.sessionLabel, sessionLabelKey_part);
            raw   = nexGenerate_phaseMap(items);   % returns {phase, color}
            lut   = table(raw.phase, raw.color, 'VariableNames', {'label', 'color'});
        end

        nexon.console.BASE.registry.LUT.(fieldKey) = lut;      
    end
        
    %% REGION MAPPINGS (MULTI-SUBJECT)
    subjects = nexon.console.BASE.registry.categories.subj;
    params = nexon.console.BASE.params;        
    for i = 1:length(subjects)
        subject=subjects(i);
        % regMap = [];            
        subjectDir_local =  fullfile(params.paths.projDir_local,"Experiments",params.extractCfg.experiment,"Subjects",subject);
        subjectDir_cloud =  fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Subjects",subject);
        regMapDir_local = fullfile(subjectDir_local,"npxls/trajectory/imec0","map_channel-region.mat");            
        regMapDir_cloud = fullfile(subjectDir_cloud,"npxls/trajectory/imec0","map_channel-region.mat");            
        try
            load(regMapDir_local);
        catch
            try
                load(regMapDir_cloud);
            catch
                continue   % no region map for this subject (e.g. a new cohort) —
                           % skip it, don't abort the whole registry build
            end
        end
        subjectID = sprintf("subj_%s",subject);
        subjectID = strrep(subjectID,"-","_");
        nexon.console.BASE.registry.SUBJ.(subjectID).regMap=regMap;
        % Atlas annotation — load probabilistic posterior; falls back to NTE prior
        subjectDir = subjectDir_local;
        if ~isfolder(subjectDir), subjectDir = subjectDir_cloud; end
        nexAtlas_initSubject(nexon, subjectID, subjectDir);
    end


end

% res=cellfun(@(df) (df==9.669406058356351), rThresh,"UniformOutput",false)
% isEmp=cellfun(@(r) (r==1), res, "UniformOutput",true);
% res(isEmp==1)=num2cell(0);
% res_final = (cat(1,res(:)));
