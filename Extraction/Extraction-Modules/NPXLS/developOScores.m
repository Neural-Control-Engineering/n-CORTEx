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
    FRQ_pre = [];
    FRQ_post = [];
    if numPhases > 0
        for i = 1:numPhases
            phase = phases(i);
            disp(phase);
            % lfpGroup = LFP(contains(LFP.sessionLabel,phase),:);
            phaseCmp = arrayfun(@(x) strcmp(parseSessionLabel(x,"phase"),phase), LFP.sessionLabel, "UniformOutput", true);
            % phaseCmp = strcmp(parseSessionLabel(LFP.sessionLabel,"phase"),phase);
            lfpGroup = LFP(phaseCmp,:);
            % tEvent = times(phaseCmp,:);
            tEvent = cellfun(@(x) ([1:size(x,2)]-1750)./args.Fs, lfpGroup.lfp, "UniformOutput", false);
            [oscPRE, oscPOST, mPRE, mPOST, frqPRE, frqPOST, P] = computeOScores(params, lfpGroup, tEvent);
            plotOScores(params, oscPRE, oscPOST, mPRE, mPOST, P, phase, event);               
            
            FRQ_pre = [FRQ_pre; struct2table(frqPRE)];
            FRQ_post = [FRQ_post; struct2table(frqPOST)];            
            FRQ_pre.sessionLabel = cellfun(@(x) string(x), FRQ_pre.sessionLabel, "UniformOutput",true);
            FRQ_post.sessionLabel = cellfun(@(x) string(x), FRQ_post.sessionLabel, "UniformOutput",true);            

            PREScores = [PREScores; oscPRE];
            mPREScores = [mPREScores; mPRE];
            POSTScores = [POSTScores; oscPOST];
            mPOSTScores = [mPOSTScores; mPOST];                  
        end
        LFP = outerjoin(LFP, FRQ_post, "Keys", {'sessionLabel','trialNum'},"MergeKeys",true);    
    end
    res.PREScores = PREScores;
    res.mPREScores = mPREScores;
    res.POSTScores = POSTScores;
    res.mPOSTScores = mPOSTScores;
    res.FRQ_pre = FRQ_pre;
    res.FRQ_post = FRQ_post;
    res.phases = phases;
    res.P = P;
end