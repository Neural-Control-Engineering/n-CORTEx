function [dfCol_avg, dfCol_sem] = nex_colAvg(dfCol, dim)
    minLength = arrayfun(@(x) size(x{1},dim), dfCol,"UniformOutput",true);
    isEmptyIdx = cellfun(@(x) isempty(x), dfCol);
    dfCol = dfCol(~isEmptyIdx);
    minLength(minLength==0) = [];
    minLength(minLength==1) = [];    
    minLength = min(minLength);    
    idxs = [1:minLength];
    dfCol_trim = cellfun(@(x) nex_trimDf(x,dim,idxs),dfCol,"UniformOutput",false);
    catDim = ndims(dfCol{1})+1;
    dfCol_avg = cat(catDim,dfCol_trim{:});
    % dfCol_sem = std(dfCol_avg,0,catDim) ./ sqrt(size(dfCol_avg,1));
    dfCol_sem = std(dfCol_avg,0,catDim) ./ sqrt(size(dfCol,1));
    dfCol_avg = mean(dfCol_avg,catDim);
    
end