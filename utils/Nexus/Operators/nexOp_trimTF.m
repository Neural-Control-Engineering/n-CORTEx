function [dfCol_trim, ax_trim] = nexOp_trimTF(TF, regAxis, ftrAxis)
    % regAxis/ftrAxis (optional): when both given, the FTR dimension (the
    % one regAxis's co-indexed sibling owns, e.g. 'unit' when REG='chans')
    % and the regAxis/ftrAxis .ax fields are excluded from trimming — left
    % exactly as each DF's own nexOp_alignCoAxes output, rather than forced
    % down to one shared min-width/representative-row shape. Needed when TF
    % can legitimately span DFs canonicalized to DIFFERENT widths (e.g.
    % mdlObject.compileSTAT building STAT across multiple subjects, each
    % per-subject-canonicalized to its own REG width via
    % nexOp_compileSTAT's withinSubject gate) — trimming/broadcasting that
    % axis here would otherwise silently force every row to share one
    % arbitrary row's REG identity. Omit for the original behavior (trim
    % every axis/dim uniformly to the shared minimum).
    if nargin < 2, regAxis = ''; end
    if nargin < 3, ftrAxis = ''; end
    skipFTR = ~isempty(regAxis) && ~isempty(ftrAxis);

    ftrDim = [];
    if skipFTR
        try
            refPtr = nexInit_axisPointer(TF{1}.df, TF{1}.ax);
            ftrDim = refPtr.(ftrAxis).dim;
            if isempty(ftrDim), skipFTR = false; end
        catch
            skipFTR = false;
        end
    end

    % dfCol_trim = cellfun(@(x) nex_trimDf(x.df,dimSel,idxs),TF,"UniformOutput",false);
    % get minLengths along each dim of the TF
    SZ = cellfun(@(x) size(x.df), TF, "UniformOutput", false);
    SZ = cat(1,SZ{:});
    sz_min = num2cell(min(SZ, [], 1));
    % for each size, trim
    % slice
    slice = repmat({':'},1,length(sz_min));
    slice = cellfun(@(idx, lim) [1:lim], slice, sz_min, "UniformOutput", false);
    if skipFTR && ftrDim <= numel(slice)
        slice{ftrDim} = ':';   % leave this dim's own per-DF extent alone
    end
    dfCol_trim = cellfun(@(DF) DF.df(slice{:}), TF, "UniformOutput", false);
    % for each corresponding ax
    TF_ax = cellfun(@(DF)struct2cell(DF.ax)', TF, "UniformOutput", false);
    FN_ax = cellfun(@(DF)fieldnames(DF.ax)', TF, "UniformOutput", false);
    LIM_ax = cellfun(@(AX) cellfun(@(ax) length(ax), AX, "UniformOutput", false), TF_ax, "UniformOutput", false);
    lims_min = min(cell2mat(cat(1, LIM_ax{:})),[],1); % extract min length for each ax
    if skipFTR
        skipMask = ismember(FN_ax{1}, {regAxis, ftrAxis});
        lims_min(skipMask) = Inf;   % never trim these — see header comment
    end
    lims_min = num2cell(lims_min); % wrap into cell for cellfun
    TRIM_ax = cellfun(@(AX) cellfun(@(ax, lim) ax(1:min(lim, numel(ax))), AX, lims_min, "UniformOutput", false), TF_ax, "UniformOutput", false);
    TF_ax_trim = cellfun(@(AX, FN) cell2struct(AX', FN'), TRIM_ax,  FN_ax, "UniformOutput", false);
    % tentative, return first ax in TF as representative 'ax_trim'
    ax_trim = TF_ax_trim{1};
end
