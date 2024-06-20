function buildExtractionLogs(extLogPath, dataLayers)
    disp(extLogPath);
    % extractionLog = table([],[],[],'VariableNames', {'SessionName', 'Extracted', 'TrialMask'},'VariableTypes',{'cell','double','cell'});
    varNames = {'SessionName','Extracted','TrialMask'};
    varSize = size(varNames);
    varSize(1)=0;
    extractionLog  = table('Size',varSize,'VariableNames', varNames,'VariableTypes',{'cell','double','cell'});
    for i = 1:length(dataLayers)
        dataLayer = dataLayers(i);
        extLogName = sprintf("%s_extraction_log.csv",dataLayer);
        writetable(extractionLog,fullfile(extLogPath,extLogName));        
    end

end