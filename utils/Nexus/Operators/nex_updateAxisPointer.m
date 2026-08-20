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

    % Nothing to update from an empty read (e.g. a figure reloading a dfID the
    % newly-routed trial doesn't carry — a PCA output on a fresh capture trial).
    % Bail rather than dot-index an empty DF_postOp.
    if isempty(DF), return; end
    try
        axFields = string(fieldnames(DF.ax))';
    catch
        return;
    end
    df        = DF.df;
    dimsTaken = [];

    % Co-indexed labels (e.g. per-unit 'chans') yield a shared dimension to their
    % sibling (e.g. 'unit') EXPLICITLY, not by field order. The old order-only
    % rule ("chans comes after unit so unit grabs the dim first") holds in memory
    % (insertion order: unit…chans) but NOT on a disk round-trip, where HDF5
    % returns axes alphabetically (chans…unit) — there chans would grab the dim
    % and unit would resolve to []. This explicit yield keeps the dim owner stable
    % across memory/disk, matching nexInit_axisPointer / nex_initAxisPointer_v2.
    coIndexLabels = nex_coIndexAxisLabels();
    axLens        = arrayfun(@(f) numel(DF.ax.(char(f))), axFields);

    for i = 1:numel(axFields)
        ax    = char(axFields(i));
        axLen = length(DF.ax.(ax));

        if ismember(string(ax), coIndexLabels) && sum(axLens == axLen) > 1
            dim = [];   % co-indexed label with a same-length sibling — yield the dim
        else
            % Claim the first array dimension of matching length not already taken.
            dims = find(axLen == size(df));
            dim  = [];
            for j = 1:numel(dims)
                if ~ismember(dims(j), dimsTaken)
                    dim = dims(j);
                    break;
                end
            end
            if ~isempty(dim), dimsTaken = [dimsTaken, dim]; end
        end

        if isprop(ptr, ax)
            % Existing axis: update dim, clamp value and range to new length.
            % When axLen == 0 the DF is transiently empty (e.g. a router update
            % fired while realtime data was still arriving).  Clamping to 0
            % would corrupt range → [0,0] and value → 0, stalling animation
            % for every tick until the next updateScope with real data.
            % Preserve all numeric fields and let the next non-empty update
            % reconcile them.
            tmp     = ptr.(ax);
            tmp.dim = dim;
            if axLen > 0
                tmp.value  = min(tmp.value, axLen);
                tmp.range  = [min(tmp.range(1), axLen), min(tmp.range(2), axLen)];
                if isfield(tmp, 'window') && ~isempty(tmp.window)
                    tmp.window = min(tmp.window, axLen);
                else
                    tmp.window = axLen;
                end
            end
            ptr.(ax) = tmp;
        else
            % New axis: add dynamic property with defaults
            addprop(ptr, ax);
            ptr.(ax) = struct('dim', dim, 'value', 1, 'range', [1, axLen], 'window', axLen);
        end
    end
end
