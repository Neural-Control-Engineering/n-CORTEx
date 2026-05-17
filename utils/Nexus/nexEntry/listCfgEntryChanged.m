function listCfgEntryChanged(src, event, key, selectionBus)
    selectionBus.selections.(key) = src.Value;
    parent = selectionBus.Parent;
    if isa(parent, 'nexObj_selectionBus')
        % Items bus of nexObj_categorical — enumerate items for the new selection
        parent.updateScope(char(key), src.String{src.Value(end)});
    elseif ismethod(parent, 'visualize')
        % Only update ptr.(key).indices for the axis that just changed.
        % A full sync would overwrite unrelated axes from stale bus values.
        if isprop(parent, 'DF_postOp') && ~isempty(parent.DF_postOp) ...
                && ~isempty(parent.DF_postOp.ptr) ...
                && (isprop(parent.DF_postOp.ptr, key) || isfield(parent.DF_postOp.ptr, key))
            p = parent.DF_postOp.ptr.(key);
            if isstruct(p) && isfield(p, 'dim')
                sel = src.Value;
                if ~isempty(sel) && isnumeric(sel)
                    p.indices = sort(double(sel(:)'));
                else
                    p.indices = [];
                end
                parent.DF_postOp.ptr.(key) = p;
            end
        end
        parent.visualize();
    end
end
