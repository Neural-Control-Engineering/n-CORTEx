function axTitle = nexTract_axisTitle(nexObj, DF, dimList)
    domain = nexObj.domain;
    if nargin < 3 || isempty(dimList)
        dimList = domain.D2;
    end
    ptr    = DF.ptr;
    axTitle = "";
    for i = 1:length(dimList)
        d = dimList(i);
        try
            binIDs = DF.labels.(d);
        catch
            binIDs = DF.ax.(d);
        end
        nTotal = numel(binIDs);
        p      = ptr.(d);

        % Prefer indices (written by both Pointer bus and axisPtrChanged)
        if isfield(p, 'indices') && ~isempty(p.indices)
            idxArr = sort(p.indices(p.indices >= 1 & p.indices <= nTotal));
        else
            idxArr = [];
        end

        if numel(idxArr) == 1
            binID = binIDs(idxArr);
            axTitle = nexTract_fmtSingle(axTitle, d, binID);
        elseif numel(idxArr) > 1
            lo = binIDs(idxArr(1));
            hi = binIDs(idxArr(end));
            axTitle = nexTract_fmtRange(axTitle, d, lo, hi);
        else
            % fallback: scalar value from axisPanel
            binIdx = max(1, min(round(p.value), nTotal));
            binID  = binIDs(binIdx);
            axTitle = nexTract_fmtSingle(axTitle, d, binID);
        end

        if i ~= length(dimList)
            axTitle = strcat(axTitle, ' |');
        end
    end
    % Swap '_' for '-' before display -- MATLAB's default 'tex' title/
    % label interpreter reads an underscore as "start subscript," which
    % mangles real column/value names (e.g. "sessionLabel_subj",
    % "h5_responseThreshold_g") into partially-subscripted text. Applied
    % once here, globally, rather than per-caller, since every consumer
    % of this title string (monoGram, monoGraph, stateSpace) hits the
    % same underscore-heavy real column names.
    axTitle = strrep(axTitle, '_', '-');
end

function s = nexTract_fmtSingle(s, d, binID)
    switch class(binID)
        case "string", s = strcat(s, d, ':', {' '}, binID);
        case "double", s = strcat(s, d, ':', {' '}, num2str(binID));
        otherwise,     s = strcat(s, d, ':', {' '}, string(binID));
    end
end

function s = nexTract_fmtRange(s, d, lo, hi)
    switch class(lo)
        case "string", s = strcat(s, d, ': ', lo, char(8211), hi);
        case "double", s = strcat(s, d, ': ', num2str(lo), char(8211), num2str(hi));
        otherwise,     s = strcat(s, d, ': ', string(lo), char(8211), string(hi));
    end
end
