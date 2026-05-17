function ptr = nexOp_syncPtrFromBus(ptr, ptrBus)
% Write ptrBus.selections into ptr.(axName).indices for every axis.
%
% For nexObj_ptr handles : updated in place (return value may be ignored).
% For plain structs      : caller MUST use the returned value.
%
% After this call, ptr.(axName).indices holds the listbox selection as a
% sorted index array.  Empty or missing selections leave .indices = [].
% ptr.range and ptr.value are not touched.

    if isempty(ptr) || isempty(ptrBus), return; end

    % collector.Pointer is a nexObj_selectionBus handle — use isprop, not isfield.
    if ~isprop(ptrBus, 'selections') && ~isfield(ptrBus, 'selections'), return; end
    busSel = ptrBus.selections;
    if isempty(busSel), return; end

    if isstruct(ptr)
        ptrFields = fieldnames(ptr);
    else
        ptrFields = properties(ptr);
    end

    for fi = 1:numel(ptrFields)
        f = ptrFields{fi};
        if ~isfield(busSel, f), continue; end  % leave axes absent from bus untouched
        p = ptr.(f);
        if ~isstruct(p) || ~isfield(p, 'dim'), continue; end
        sel = busSel.(f);
        if ~isempty(sel) && isnumeric(sel)
            p.indices = sort(double(sel(:)'));
        else
            p.indices = [];
        end
        ptr.(f) = p;
    end
end
