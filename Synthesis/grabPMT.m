function pmt_sample = grabPMT(sampleLabel, F)        
    trialNum = str2double(parseSessionLabel(sampleLabel,"trialNum"));
    chanNum = str2double(parseSessionLabel(sampleLabel,"chanNum"));
    gIdx = strfind(sampleLabel,"g0");
    sessionLabel = char(sampleLabel);
    sessionLabel = string(sessionLabel(1:gIdx+1));
    % retrieve corresponding PMT  (from F)
    sessionRow = F(contains(F.sessionLabel,sessionLabel) & ismember(F.trialNum,trialNum),:);    
    specs = sessionRow.fooofparams{1};
    specs = specs(chanNum,:);
    PMT = sessionRow.powspctrm_pmt{1};
    PMT = PMT(:,chanNum);
    pmtCond = [1:size(specs.power_spectrum,2)];
    pmt_sample = log10(PMT(pmtCond))';

end