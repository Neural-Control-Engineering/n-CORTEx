function row_dts = dtsIO_compileDTS(s_dts, preFix)
    % s_dts : struct containing dts column-wise data
    dtsFields = fieldnames(s_dts);
    if isempty(preFix)
        preFix="";
    else
        preFix = strcat(preFix,"_");
    end
    row = [];
    for i = 1:length(dtsFields)
        dtsField = dtsFields{i};        
        dtsColName = sprintf("%s%s",preFix,dtsField);
        dtsVal = s_dts.(dtsField);
        if isstruct(dtsVal)
            row = [row, dtsIO_compileDTS(dtsVal, dtsField)];
        elseif ~isscalar(dtsVal) && ~ischar(dtsVal)
            % Any non-scalar array is per-trial DF data → one cell per row. Test
            % scalar-ness, NOT size(,1)>1: a row vector (1×N axis) has size(1,·)==1
            % and would otherwise be stored un-celled, breaking dtsIO_composeDF's
            % brace read. Scalars and char labels stay bare (manifest columns).
            row = [row, table({dtsVal}, 'VariableNames', dtsColName)];
        else
            row = [row, table(dtsVal, 'VariableNames', dtsColName)];
        end
    end
    row_dts = row;
end