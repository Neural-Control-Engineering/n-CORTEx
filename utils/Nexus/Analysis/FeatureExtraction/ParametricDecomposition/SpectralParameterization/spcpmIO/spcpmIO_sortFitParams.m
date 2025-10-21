function fitParams_sort = spcpmIO_sortFitParams(fitParams)
    sortKey_CF="CF";
    sortKey_PW="PW";
    sortKey_BW="BW";
    % filter CFs to map sort transision
    fitTable = struct2table(fitParams);
    fitCols = fitTable.Properties.VariableNames;
    CFCols = convertCharsToStrings(fitCols(contains(fitCols,sortKey_CF)));
    CFVals = fitTable(:,CFCols);
    % sort by val (retain idx)
    fitTable_Peaks = fitTable(:,contains(fitCols,sortKey_CF)|contains(fitCols,sortKey_PW)|contains(fitCols,sortKey_BW));    
    fitTable_CFs = fitTable(:,contains(fitCols,sortKey_CF));
    % omit '0' center frequenceis
    cfVals = fitTable_CFs{1,:};
    cfVals = cfVals(cfVals~=0);
    [fitTable_CFSort, sortIdx] = sort(cfVals);
    if all(sortIdx==[1:length(cfVals)])
        fitParams_sort=fitParams;
        return
    end
    disp("sorting parameters...");
    % re-fill empty peaks to length of peakCols        
    imputeVector = [max(sortIdx)+1:width(fitTable_CFs)];
    sortIdx = [sortIdx, imputeVector];    
    % index peak params in bulk (to handle bulk sort transision)
    % extract numeric val in peakColnames
    peakCols = convertCharsToStrings(fitTable_Peaks.Properties.VariableNames);
    peakVals = fitTable_Peaks{:,peakCols};
    peakCols_num = str2double(regexp(peakCols,"\d+","match","once"));
    % extract a row-wise representation
    % peakTable = table(peakCols_num',peakVals',peakCols',"VariableNames",["Order","Value","Name"]);
    peakTable = table(peakCols_num(:), peakVals(:), peakCols(:), ...
    VariableNames=["Order","Value","Name"]);
    % replace nums, collectively
    sortIdx_bulk = arrayfun(@(x) find(sortIdx==x), peakTable.Order,"UniformOutput",true);
    peakTable.Order=sortIdx_bulk;
    peakTable_sort = sortrows(peakTable,"Order");
    peakTable_sort.Name=peakTable.Name;
    % revert to original form
    % fitTable_peaks_sort = table(peakTable_sort.Value(:)', VariableNames=peakTable_sort.Name)
    fitTable_peaks_sort = array2table(peakTable_sort.Value(:)', ...
    'VariableNames', cellstr(peakTable_sort.Name));
    % replace original fitTable peakCols and vals
    % fitTable_OG = fitTable;
    fitTable(:,peakCols)=fitTable_peaks_sort;
    fitParams_sort = table2struct(fitTable);
end