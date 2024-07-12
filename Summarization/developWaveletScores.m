function [LFP, res] = developWaveletScores(params, LFP, args)
    if isempty(args); args = struct; end
    if ~isfield(args,"Fs"); args.Fs = 500; end
    % if ~isfield(args,"t"); args.t = []; end
    times = cellfun(@(x) ([1:size(x,2)]-1750)./args.Fs, LFP.lfp, "UniformOutput", false);
    event = "stim-onset";
    
    % clean datastore
    lfpCol = LFP.lfp;
    lfpIdx = cell2mat(cellfun(@(x) ~isempty(x), lfpCol, "UniformOutput", false));    
    LFP = LFP(lfpIdx,:);
    times= times(lfpIdx,:);
    notNan = cell2mat(cellfun(@(x) ~isnan(unpackUnitCells(x)), LFP.lfp, "UniformOutput", false));
    LFP = LFP(notNan,:);
    times = times(notNan,:);
    % Categorize
    sessionLabels = (LFP.sessionLabel);
    % % unique phases
    phases = convertCharsToStrings(cellfun(@(x) parseSessionLabel(x,"phase"), sessionLabels, "UniformOutput",true));
    phases = unique(phases);
    phases = phases(contains(phases,"paw"));
    % % unique subjects
    subjects = convertCharsToStrings(cellfun(@(x) parseSessionLabel(x,"subj"), sessionLabels, "UniformOutput",true));
    subject = unique(subjects);
    subjectListTitle = strjoin(subject,"; ");
    numPhases = length(phases);
    % computeWaveletScores / plotWaveletScores
    PREScores = {};
    POSTScores = {};
    if numPhases > 0
        for i = 1:numPhases
            phase = phases(i);
            disp(phase);
            % lfpGroup = LFP(contains(LFP.sessionLabel,phase),:);
            phaseCmp = arrayfun(@(x) strcmp(parseSessionLabel(x,"phase"),phase), LFP.sessionLabel, "UniformOutput", true);
            % phaseCmp = strcmp(parseSessionLabel(LFP.sessionLabel,"phase"),phase);
            lfpGroup = LFP(phaseCmp,:);
            tEvent = times(phaseCmp,:);
            [PRE, POST, P] = computeWaveletScores(params, lfpGroup, tEvent);
            plotWaveletScores(PRE, POST, P, phase, event);
            PREScores = [PREScores; PRE];
            POSTScores = [POSTScores; POST];
        end
    end
    res.PREScores = PREScores;
    res.POSTScores = POSTScores;
    res.phases = phases;
    res.P = P;
    

end