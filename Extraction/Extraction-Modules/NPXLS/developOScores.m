function [LFP, res] = developOScores(params, LFP, args)
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
    load(fullfile(params.paths.projDir_cloud,"Experiments",params.experiment,"Subjects/",subject,"npxls/trajectory/imec0/map_channel-region.mat"));
    params.regMap = regMap;
    subjectListTitle = strjoin(subject,"; ");
    numPhases = length(phases);
    % computeWaveletScores / plotWaveletScores
    PREScores = {};
    POSTScores = {};
    mPREScores = {};
    mPOSTScores = {};
    if numPhases > 0
        for i = 1:numPhases
            phase = phases(i);
            disp(phase);
            % lfpGroup = LFP(contains(LFP.sessionLabel,phase),:);
            phaseCmp = arrayfun(@(x) strcmp(parseSessionLabel(x,"phase"),phase), LFP.sessionLabel, "UniformOutput", true);
            % phaseCmp = strcmp(parseSessionLabel(LFP.sessionLabel,"phase"),phase);
            lfpGroup = LFP(phaseCmp,:);
            tEvent = times(phaseCmp,:);
            [oscPRE, oscPOST, mPRE, mPOST, P] = computeOScores(params, lfpGroup, tEvent);
            plotOScores(params, oscPRE, oscPOST, mPRE, mPOST, P, phase, event);            

            PREScores = [PREScores; PRE];
            mPREScores = [mPREScores; mPRE];
            POSTScores = [POSTScores; POST];
            mPOSTScores = [mPOSTcores; mPOST];           
        end
    end
    res.PREScores = PREScores;
    res.mPREScores = mPREScores;
    res.POSTScores = POSTScores;
    res.mPOSTScores = mPOSTScores;
    res.phases = phases;
    res.P = P;
end