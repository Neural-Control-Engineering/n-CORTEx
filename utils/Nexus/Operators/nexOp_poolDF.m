function data_out = nexOp_poolDF(pMap, data, ptr)
    % Pool a dataframe or STAT/AVG table using pMap.
    %
    % Handles two input shapes:
    %   TABLE  — STAT or AVG table with 'df' (cell) and 'ax' (cell of struct) columns.
    %            Each row is pooled independently via nexOp_poolAxes.  Updated 'df',
    %            'ax', and 'ptr' are written back; all other columns are preserved.
    %
    %   DF     — struct or handle object with .df and .ax fields.
    %            nexOp_poolAxes is called directly; updated ptr is re-derived via
    %            nex_initAxisPointer_v2 and attached to output.
    %
    % ptr (optional) — supplies .dim values when a table row has no per-row ptr, or
    %                  when calling on a DF without a ptr.  Pass DF_postOp.ptr.
    %
    % Output always matches the format of the input (table → table, DF → DF).

    if nargin < 3, ptr = []; end

    data_out = data;
    if isempty(pMap) || isempty(data), return; end

    if istable(data)
        hasAx  = ismember('ax',  data.Properties.VariableNames);
        hasPtr = ismember('ptr', data.Properties.VariableNames);
        if ~ismember('df', data.Properties.VariableNames) || ~hasAx
            return;
        end
        if ~hasPtr
            data_out.ptr = cell(height(data), 1);
        end
        for i = 1:height(data)
            df_i.df = data.df{i};
            try
                df_i.ax = data.ax{i};
            catch
                df_i.ax = data.ax(i);
            end
            if hasPtr && ~isempty(data.ptr(i))
                try
                    ptr_i = data.ptr{i};
                catch
                    ptr_i = data.ptr(i);
                end
            elseif ~isempty(ptr)
                ptr_i = ptr;
            else
                warning('nexOp_poolDF: no ptr for row %d — skipping', i);
                continue;
            end
            df_pooled       = nexOp_poolAxes(pMap, df_i, ptr_i);
            data_out.df{i}  = df_pooled.df;
            try
                data_out.ax{i}  = df_pooled.ax;
            catch
                data_out.ax(i)  = df_pooled.ax;
            end
            try
                data_out.ptr{i} = nexInit_axisPointer(df_pooled.df, df_pooled.ax);
            catch
                data_out.ptr(i) = nexInit_axisPointer(df_pooled.df, df_pooled.ax);
            end
        end

    else
        % DF struct or handle object
        if isempty(ptr)
            if isstruct(data) && isfield(data, 'ptr')
                ptr = data.ptr;
            elseif isobject(data) && isprop(data, 'ptr')
                ptr = data.ptr;
            end
        end
        if isempty(ptr)
            warning('nexOp_poolDF: no ptr available — returning unpooled');
            return;
        end
        data_out     = nexOp_poolAxes(pMap, data, ptr);
        ptr_updated  = nexInit_axisPointer(data_out.df, data_out.ax);
        if isstruct(data_out)
            data_out.ptr = ptr_updated;
        elseif isobject(data_out) && isprop(data_out, 'ptr')
            data_out.ptr = ptr_updated;
        end
    end
end
