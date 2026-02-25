function DF_avg = nexOp_averageTF(TF, ptr, dimSel)
    % trim all samples to identical length along dimSel
    minLength = cellfun(@(x) size(x.df,dimSel), TF,"UniformOutput",true);
    % exclude empty entries
    isEmptyIdx = cellfun(@(x) isempty(x), TF);
    TF = TF(~isEmptyIdx);
    % exclude 'empty' lengths
    minLength(minLength==0) = [];
    minLength(minLength==1) = [];    
    minLength = min(minLength);    
    idxs = [1:minLength];
    % trim df
    % dfCol_trim = cellfun(@(x) nex_trimDf(x.df,dimSel,idxs),TF,"UniformOutput",false);
    [dfCol_trim, ax_trim] = nexOp_trimTF(TF);
    % dfCol_trim = cellfun(@(DF) DF.df, TF_trim, "UniformOutput", false);
    % trim ax
    %% TEST REMOVAL
    % ptrProps = properties(ptr);
    % ptrDims = cellfun(@(p) (ptr.(p).dim), ptrProps, 'UniformOutput', true);
    % axDim = find(ptrDims==dimSel); axDim = ptrProps{axDim};
    % axTrim = cellfun(@(x) nex_trimDf(x.ax.(axDim), 2, idxs), TF, "UniformOutput", false);
    %% TEST REMOVAL
    % ax_avg = TF{1}.ax;
    labels_avg = TF{1}.labels; %% TESTING, FIX SOON (not trimmed yet corresponding with ax_trim)
    % ax_avg.(axDim) = ax_tririm{1};    
    catDim = ndims(dfCol_trim{1})+1;
    dfCol_avg = cat(catDim,dfCol_trim{:});
    % dfCol_sem = std(dfCol_avg,0,catDim) ./ sqrt(size(dfCol_avg,1));
    dfCol_sem = std(dfCol_avg,0,catDim) ./ sqrt(size(dfCol_trim,1));
    dfCol_avg = mean(dfCol_avg,catDim);
    DF_avg.df = dfCol_avg;
    DF_avg.sem = dfCol_sem;
    % DF_avg.ax = ax_avg;
    DF_avg.ax = ax_trim;
    DF_avg.labels=labels_avg;
end