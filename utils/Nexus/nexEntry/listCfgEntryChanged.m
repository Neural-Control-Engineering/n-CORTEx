function listCfgEntryChanged(src, event, key, selectionBus)
    % Whole-struct replacement so PostSet fires on selectionBus.selections,
    % allowing addlistener('selections','PostSet',...) to propagate changes
    % (field-level assignment sel.(key)=val never fires PostSet).
    newSel = selectionBus.selections;
    newSel.(key) = src.Value;
    selectionBus.selections = newSel;
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
                sel = sort(double(src.Value(:)'));
                if ~isempty(sel) && isnumeric(sel)
                    p.indices  = sel;
                    % Pointer bus owns Sta/Stp (ptr.range) and Val (ptr.value).
                    % Win (ptr.window) is an independent sub-context control.
                    p.range(1) = sel(1);
                    p.range(2) = sel(end);
                    p.value    = sel(round(end/2));
                else
                    p.indices = [];
                end
                parent.DF_postOp.ptr.(key) = p;
                % Update Sta/Stp and Val spinners; leave Win spinner untouched.
                try
                    ef = parent.Figure.windowCfgPanel.editFields.(key);
                    if ~isempty(sel)
                        ef.rangeStart.Value = p.range(1);
                        ef.rangeEnd.Value   = p.range(2);
                        ef.uiField.Value    = p.value;
                    end
                catch
                end
            end
        end
        parent.visualize();
    end
end
