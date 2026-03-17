function nex_updateAxisPointer(ptr, DF)
    % Update an existing nexObj_ptr handle IN-PLACE after a DF operation.
    %
    % This is the correct alternative to calling nex_initAxisPointer_v2 on a
    % DF_postOp that already has a ptr. Creating a new nexObj_ptr handle would
    % orphan any UI callbacks (axisPtrChanged, axisRangeChanged, etc.) that
    % captured the original handle by reference at figure-build time.
    %
    % Per-axis behaviour:
    %   dim    <- recomputed from new DF (structure may have changed)
    %   value  <- preserved, clamped to new axis length
    %   range  <- preserved, endpoints clamped to new axis length
    %   window <- preserved if present
    %
    % New axes (in DF.ax but not yet in ptr): added with defaults via addprop.
    % Dropped axes (in ptr but not in DF.ax): left in ptr (harmless; not read).

    axFields  = string(fieldnames(DF.ax))';
    df        = DF.df;
    dimsTaken = [];

    for i = 1:numel(axFields)
        ax    = char(axFields(i));
        axLen = length(DF.ax.(ax));

        % Recompute dim — same logic as nex_initAxisPointer_v2
        dim = find(axLen == size(df));
        if numel(dim) > 1
            for j = 1:numel(dim)
                if ~ismember(dim(j), dimsTaken)
                    dim = dim(j);
                    break;
                end
            end
        end
        dimsTaken = [dimsTaken, dim];

        if isprop(ptr, ax)
            % Existing axis: update dim, clamp value and range to new length
            tmp        = ptr.(ax);
            tmp.dim    = dim;
            tmp.value  = min(tmp.value,    axLen);
            tmp.range  = [min(tmp.range(1), axLen), min(tmp.range(2), axLen)];
            if isfield(tmp, 'window') && ~isempty(tmp.window)
                tmp.window = min(tmp.window, axLen);
            else
                tmp.window = axLen;   % default to full range if missing
            end
            ptr.(ax)   = tmp;
        else
            % New axis: add dynamic property with defaults
            addprop(ptr, ax);
            ptr.(ax) = struct('dim', dim, 'value', 1, 'range', [1, axLen], 'window', axLen);
        end
    end
end
