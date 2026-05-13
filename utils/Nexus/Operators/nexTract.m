function nexTract(nexon, fcn, dfID, mask, fcnName)
    
    if nargin < 5
        fcnName = func2str(fcn);
    end

    rowStart = 1;

    % apply analysis fcn to all rows of a DTS column indicated by dfID
    dtsRows = height(nexon.console.BASE.DTS); % visit each row
    dfID_entry = strrep(dfID,"_df","");

    % minLength to truncate long recordings if necessary
    if ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames)
        lengths = zeros(1, dtsRows);
        for ii = 1:dtsRows
            try
                info = h5info(char(nexon.console.BASE.DTS.h5_path(ii)), ...
                    char(nexon.console.BASE.DTS.h5_root(ii) + "/" + dfID_entry + "/df"));
                lengths(ii) = info.Dataspace.Size(end);
            catch
            end
        end
        minLength = min(lengths(lengths > 0));
    else
        minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID),"UniformOutput",true);
        minLength(minLength==0) = [];
        minLength = min(minLength);
    end

    dfColName = sprintf("%s_%s", dfID_entry, fcnName);

    isDiskBacked = ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames);

    DFOUT = {};
    for i = rowStart:dtsRows
        disp(i);

        % Skip rows whose output is already fully written.
        % Checks for df (real output) or df_im (last dataset written for complex output).
        % This makes nexTract safe to re-run after any interruption without
        % re-computing completed rows.
        if isDiskBacked
            h5f = char(nexon.console.BASE.DTS.h5_path(i));
            grp = char(nexon.console.BASE.DTS.h5_root(i) + "/" + dfColName);
            done = false;
            try, h5info(h5f, [grp '/df']);    done = true; catch, end
            try, h5info(h5f, [grp '/df_im']); done = true; catch, end
            if done, continue; end
        end

        DF_in = dtsIO_readDF(nexon, dfID_entry, i);
        try
            df = DF_in.df;
        catch
            continue
        end
        if ~isempty(df)
            try
                if size(df,2) > minLength * 1.01
                    ptr = nexInit_axisPointer(DF_in.df, DF_in.ax);
                    DF_in.df = df(:,1:minLength);
                    axFields = convertCharsToStrings(fieldnames(DF_in.ax));
                    axDims = [];
                    for j=1:length(axFields); axDims = [axDims; ptr.(axFields(j)).dim]; end
                    axSel = axFields(axDims==2);
                    try
                    ax = DF_in.ax.(axSel);
                    catch
                        try
                            ax = DF_in.ax.t;
                            axSel="t";
                        catch e
                            disp(getReport(e));
                        end
                    end
                    ax2Trim = ax(1:minLength);
                    DF_in.ax.(axSel)=ax2Trim;
                end
                args = extractMethodCfg(fcnName);
                args.idx_row=i;
                DF_out = fcn(DF_in, args);
            catch e
                disp(getReport(e));
                continue
            end
        else
            continue
        end
        try
            dtsIO_writeDF(nexon,DF_out,dfColName,i);
        catch e
            warning("nexTract: write failed for row %d — %s\nAborting.", i, e.message);
            break
        end
    end
    % assign to new column with custom dfID
    
end