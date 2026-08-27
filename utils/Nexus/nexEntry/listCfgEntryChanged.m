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
                sel = sort(double(src.Value(:)'));
                if ~isempty(sel) && isnumeric(sel)
                    p.indices = sel;
                    % Bidirectional sync: map selection → (value, window) so the
                    % Window panel always reflects the Pointer context.
                    p.value  = sel(round(end/2));
                    p.window = numel(sel);
                else
                    p.indices = [];
                end
                parent.DF_postOp.ptr.(key) = p;
                % Update Window-panel spinners if present.
                try
                    ef = parent.Figure.windowCfgPanel.editFields.(key);
                    if ~isempty(sel)
                        ef.uiField.Value = p.value;
                        ef.window.Value  = p.window;
                    end
                catch
                end
            end
        end
        parent.visualize();
    end
end
