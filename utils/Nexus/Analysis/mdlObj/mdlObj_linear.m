classdef mdlObj_linear < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_linear(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "linear", dfID_source, [], headline);
            mdlObj.py.np = py.importlib.import_module('numpy');
            mdlObj.cfg.fitCfg  = nex_generateCfgObj(str2func("nexFit_linear"));
            mdlObj.cfg.dmCfg.format = "regression";
        end

        function Y_pred = predict(mdlObj, X)
            np    = mdlObj.py.np;
            X_py  = np.array(double(X));
            Y_py  = mdlObj.model.predict(X_py);
            Y_pred = double(np.array(Y_py));
        end

        % ── Results lifecycle ─────────────────────────────────────────────

        function storeResult(mdlObj, resultID, data)
            mdlObj.RESULTS.(resultID) = data;
            % Append to SRC listbox if figure is live
            bus = mdlObj.collector.View;
            if ~ismember(resultID, bus.selKeys.SRC)
                bus.selKeys.SRC = [bus.selKeys.SRC, string(resultID)];
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                        && isvalid(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.String = cellstr(bus.selKeys.SRC);
                    bus.listBoxes.SRC.Max    = numel(bus.selKeys.SRC);
                end
            end
            mdlObj.applySRC(resultID);
        end

        function applySRC(mdlObj, srcKey)
        % Switch active source and refresh canvas.
        % srcKey = 'fit'       → Y_pred vs Y_actual scatter.
        % srcKey = <resultID>  → populate VW/CLR from RESULTS axes, render CV plot.
            srcKey = char(srcKey);
            isFit  = strcmp(srcKey, 'fit');
            bus    = mdlObj.collector.View;

            % Sync SRC listbox selection
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                idx = find(bus.selKeys.SRC == string(srcKey), 1);
                if ~isempty(idx)
                    bus.listBoxes.SRC.Value = idx;
                    bus.selections.SRC      = idx;
                end
            end

            if isFit
                % Clear VW and CLR when in fit mode
                bus.selKeys.CLR = "";
                bus.selKeys.VW  = "";
                if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                        && isvalid(bus.listBoxes.VW)
                    bus.listBoxes.VW.String = {};
                    bus.listBoxes.VW.Value  = [];
                end
                if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                        && isvalid(bus.listBoxes.CLR)
                    bus.listBoxes.CLR.String = {};
                    bus.listBoxes.CLR.Value  = [];
                end
            else
                if isfield(mdlObj.RESULTS, srcKey)
                    mdlObj.refreshVW(srcKey);

                    % Populate CLR from result axis names (exclude permute)
                    R = mdlObj.RESULTS.(srcKey);
                    if isstruct(R.ax)
                        axNames = string(fieldnames(R.ax))';
                        clrOpts = axNames(~ismember(axNames, "permute"));
                    else
                        clrOpts = string.empty(1,0);
                    end
                    if isempty(clrOpts), clrOpts = "fold"; end
                    bus.selKeys.CLR    = clrOpts;
                    bus.selections.CLR = 1;
                    if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                            && isvalid(bus.listBoxes.CLR)
                        bus.listBoxes.CLR.String = cellstr(clrOpts);
                        bus.listBoxes.CLR.Max    = numel(clrOpts);
                        bus.listBoxes.CLR.Value  = 1;
                    end
                end
            end

            nexFigure_linear_renderSRC(mdlObj, srcKey);
        end

        function refreshVW(mdlObj, resultID)
        % Populate the VW listbox from the rows of RESULTS.(resultID).
        % Each row = one group/condition being compared.  Row labels are
        % built from non-structural grouping columns of the STAT table, or
        % from a single label if the result is a plain DF struct.
            if ~isfield(mdlObj.RESULTS, resultID), return; end
            R = mdlObj.RESULTS.(resultID);

            if istable(R)
                structural = ["df","ax","ptr","avgCfg"];
                groupCols  = setdiff(string(R.Properties.VariableNames), structural, 'stable');
                if isempty(groupCols)
                    rowLabels = arrayfun(@(i) sprintf("row_%d", i), ...
                                        (1:height(R))', 'UniformOutput', false);
                    rowLabels = string(rowLabels);
                else
                    rowLabels = string(R.(char(groupCols(1))));
                    for c = 2:numel(groupCols)
                        rowLabels = rowLabels + " | " + string(R.(char(groupCols(c))));
                    end
                end
            else
                % Plain DF struct — treat as single-row result
                rowLabels = string(resultID);
            end

            % Update bus keys and selections
            bus = mdlObj.collector.View;
            nVW = numel(rowLabels);
            bus.selKeys.VW    = rowLabels;
            bus.selections.VW = 1:nVW;

            % Update listbox if wired
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                    && isvalid(bus.listBoxes.VW)
                bus.listBoxes.VW.String = cellstr(rowLabels);
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = 1:nVW;   % all selected by default
            end
        end
    end
end
