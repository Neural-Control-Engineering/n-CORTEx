function [dfCol_trim, ax_trim] = nexOp_trimTF(TF, regAxis, ftrAxis)
    % regAxis/ftrAxis (optional): char/string for a single axis pair, OR a
    % cell array of several pairs (same length, positionally matched) when
    % mdlObj.pMap pools more than one axis in mapID/lookup mode at once
    % (e.g. 'chans'->region AND 'f'->band simultaneously). For each pair
    % that resolves, the FTR dimension (the one regAxis's co-indexed
    % sibling owns, e.g. 'unit' when regAxis='chans') and the regAxis/
    % ftrAxis .ax fields are excluded from trimming — left exactly as each
    % DF's own nexOp_alignCoAxes/pooling output, rather than forced down
    % to one shared min-width/representative-row shape. A pair whose FTR
    % dimension fails to resolve is dropped from exclusion independently —
    % it does not disable protection for any other pair that did resolve.
    % Needed when TF can legitimately span DFs canonicalized/pooled to
    % DIFFERENT widths per axis (e.g. mdlObject.compileSTAT building STAT
    % across multiple subjects, each with its own per-subject region
    % count) — trimming/broadcasting that axis here would otherwise
    % silently force every row to share one arbitrary row's identity.
    % Omit (or pass only empties) for the original behavior (trim every
    % axis/dim uniformly to the shared minimum).
    if nargin < 2, regAxis = ''; end
    if nargin < 3, ftrAxis = ''; end
    if ~iscell(regAxis), regAxis = {regAxis}; end
    if ~iscell(ftrAxis), ftrAxis = {ftrAxis}; end
    keep    = ~cellfun(@isempty, regAxis) & ~cellfun(@isempty, ftrAxis);
    regAxis = regAxis(keep);
    ftrAxis = ftrAxis(keep);

    % Resolve each pair's FTR dimension independently.
    ftrDims   = cell(size(ftrAxis));
    resolveOK = false(size(ftrAxis));
    if ~isempty(ftrAxis)
        try
            refPtr = nexInit_axisPointer(TF{1}.df, TF{1}.ax);
            for i = 1:numel(ftrAxis)
                try
                    d = refPtr.(ftrAxis{i}).dim;
                    if ~isempty(d)
                        ftrDims{i}   = d;
                        resolveOK(i) = true;
                    end
                catch
                end
            end
        catch
        end
    end
    regAxis_ok = regAxis(resolveOK);
    ftrAxis_ok = ftrAxis(resolveOK);
    ftrDims_ok = ftrDims(resolveOK);

    % dfCol_trim = cellfun(@(x) nex_trimDf(x.df,dimSel,idxs),TF,"UniformOutput",false);
    % get minLengths along each dim of the TF
    SZ = cellfun(@(x) size(x.df), TF, "UniformOutput", false);
    SZ = cat(1,SZ{:});
    sz_min = num2cell(min(SZ, [], 1));
    % for each size, trim
    % slice
    slice = repmat({':'},1,length(sz_min));
    slice = cellfun(@(idx, lim) [1:lim], slice, sz_min, "UniformOutput", false);
    for i = 1:numel(ftrDims_ok)
        d = ftrDims_ok{i};
        if d <= numel(slice), slice{d} = ':'; end   % leave this dim's own per-DF extent alone
    end
    dfCol_trim = cellfun(@(DF) DF.df(slice{:}), TF, "UniformOutput", false);
    % for each corresponding ax
    TF_ax = cellfun(@(DF)struct2cell(DF.ax)', TF, "UniformOutput", false);
    FN_ax = cellfun(@(DF)fieldnames(DF.ax)', TF, "UniformOutput", false);
    LIM_ax = cellfun(@(AX) cellfun(@(ax) length(ax), AX, "UniformOutput", false), TF_ax, "UniformOutput", false);
    lims_min = min(cell2mat(cat(1, LIM_ax{:})),[],1); % extract min length for each ax
    if ~isempty(regAxis_ok)
        skipMask = ismember(FN_ax{1}, [regAxis_ok(:); ftrAxis_ok(:)]);
        lims_min(skipMask) = Inf;   % never trim these — see header comment
    end
    lims_min = num2cell(lims_min); % wrap into cell for cellfun
    TRIM_ax = cellfun(@(AX) cellfun(@(ax, lim) ax(1:min(lim, numel(ax))), AX, lims_min, "UniformOutput", false), TF_ax, "UniformOutput", false);
    TF_ax_trim = cellfun(@(AX, FN) cell2struct(AX', FN'), TRIM_ax,  FN_ax, "UniformOutput", false);
    % tentative, return first ax in TF as representative 'ax_trim'
    ax_trim = TF_ax_trim{1};
end
