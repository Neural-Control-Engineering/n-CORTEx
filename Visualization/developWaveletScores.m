function LFP = developWaveletScores(params, LFP, args)
    
    if ~isfield(args,"Fs"); args.Fs = 500; end
    % if ~isfield(args,"t"); args.t = []; end
    times = 
    
    % clean datastore
    lfpCol = LFP.lfp;
    lfpIdx = cell2mat(cellfun(@(x) ~isempty(x), lfpCol, "UniformOutput", false));    
    LFP = LFP(lfpIdx,:);
    notNan = cell2mat(cellfun(@(x) ~isnan(unpackUnitCells(x)), LFP.lfp, "UniformOutput", false));
    LFP = LFP(notNan,:);
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
    % computeWaveletScores
    
    % plotWaveletScores

end