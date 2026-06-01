function [dfCol_trim, ax_trim] = nexOp_trimTF(TF)
    % dfCol_trim = cellfun(@(x) nex_trimDf(x.df,dimSel,idxs),TF,"UniformOutput",false);
    % get minLengths along each dim of the TF
    SZ = cellfun(@(x) size(x.df), TF, "UniformOutput", false);
    SZ = cat(1,SZ{:});
    sz_min = num2cell(min(SZ, [], 1));
    % for each size, trim
    % slice
    slice = repmat({':'},1,length(sz_min));
    slice = cellfun(@(idx, lim) [1:lim], slice, sz_min, "UniformOutput", false);
    dfCol_trim = cellfun(@(DF) DF.df(slice{:}), TF, "UniformOutput", false);
    % for each corresponding ax
    TF_ax = cellfun(@(DF)struct2cell(DF.ax)', TF, "UniformOutput", false);    
    FN_ax = cellfun(@(DF)fieldnames(DF.ax)', TF, "UniformOutput", false);    
    LIM_ax = cellfun(@(AX) cellfun(@(ax) length(ax), AX, "UniformOutput", false), TF_ax, "UniformOutput", false);
    lims_min = min(cell2mat(cat(1, LIM_ax{:})),[],1); % extract min length for each ax
    lims_min = num2cell(lims_min); % wrap into cell for cellfun
    TRIM_ax = cellfun(@(AX) cellfun(@(ax, lim) ax([1:lim]), AX, lims_min, "UniformOutput", false), TF_ax, "UniformOutput", false);
    TF_ax_trim = cellfun(@(AX, FN) cell2struct(AX', FN'), TRIM_ax,  FN_ax, "UniformOutput", false);
    % tentative, return first ax in TF as representative 'ax_trim'
    ax_trim = TF_ax_trim{1};
end