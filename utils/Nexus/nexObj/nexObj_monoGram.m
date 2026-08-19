classdef nexObj_monoGram < nexObject
    % nexObj_monoGram  2-D surf visualization (spectrogram, TF, heatmap).
    %
    % Domain convention (monoGram-specific):
    %   D1       — two display axes shown as surf rows × cols (e.g. [f, t])
    %   animate  — animation axis stepped by the player (e.g. chans)
    %   (no D2 in the waterfall sense; ANI is the only non-display axis)
    %
    % Collectors populated at construction:
    %   collector.View    — SRC / VW / CLR  (via initCollectorView)
    %   collector.Domain  — D1 (multi-select, 2 items) / ANI (single-select)
    %   collector.Pointer — per-axis value filter (via initPointerBus)
    %
    % Constructor
    %   nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain, headline)

    properties
    end

    methods

        % ── Constructor ───────────────────────────────────────────────────
        function nexObj = nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain, headline)
            if ~isempty(Parent)
                nexon = Parent.nexon;
            end
            if nargin < 5, domain   = []; end
            if nargin < 6, headline = []; end
            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);
            nexObj.classID = "mgm";

            %% DF loading
            if ~isempty(Parent)
                nexObj.DF     = Parent.DF_postOp;
                nexObj.Origin = Parent.Origin;
                nexObj.Parent.Children.(nexObj.classID) = nexObj;
            elseif ~isempty(dfID_source)
                nexObj.DF     = dtsIO_readDF(nexObj.nexon, dfID_source, []);
                nexObj.Origin = nexObj;
            end

            %% Config
            nexObj.cfg.opCfg  = [];
            if nargin >= 4 && ~isempty(opCfgFcn)
                nexObj.cfg.opCfg = nex_generateCfgObj(opCfgFcn);
            end
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGram"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));

            %% Operate → DF_postOp (preserves ptr handle across re-operates)
            nexObj.operate();

            %% Pool map
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end

            %% Domain (infer or accept override)
            if ~isempty(domain)
                nexObj.domain = domain;
            else
                nexObj.domain = nexObj.inferDomain();
            end

            %% Collector — View (SRC / VW / CLR with ax-- keys)
            nexObj.initCollectorView();

            %% Collector — Domain (D1 = two display axes, ANI = animation axis)
            axisKeys = string(fieldnames(nexObj.DF_postOp.ax))';
            if isempty(axisKeys), axisKeys = ""; end
            domainDict.D1  = axisKeys;
            domainDict.ANI = axisKeys;
            nexObj.collector.Domain = buildSelection(nexObj, domainDict);

            % Seed selections from inferred domain
            if ~isequal(axisKeys, "")
                d1Sel = [];
                for di = 1:min(2, numel(nexObj.domain.D1))
                    idx = find(axisKeys == string(nexObj.domain.D1(di)), 1);
                    if ~isempty(idx), d1Sel(end+1) = idx; end %#ok<AGROW>
                end
                if ~isempty(d1Sel)
                    nexObj.collector.Domain.selections.D1 = d1Sel;
                end
                if ~isempty(nexObj.domain.animate) && ~isequal(string(nexObj.domain.animate), "")
                    aniIdx = find(axisKeys == string(nexObj.domain.animate), 1);
                    if ~isempty(aniIdx)
                        nexObj.collector.Domain.selections.ANI = aniIdx;
                    end
                end
            end

            %% Collector — Pointer (one key per DF.ax field)
            nexObj.initPointerBus();
            % Free the default animate axis's Pointer selection so its frame is
            % driven by ptr.value (stepAnimate) rather than pinned to the default
            % single index — otherwise the player advances an ignored value and
            % the frame never changes.
            nexObj.clearAnimatePointer();

            %% Figure
            nexObj.buildFigure();

            %% Animation player
            nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
        end

        % ── Core pipeline ─────────────────────────────────────────────────

        function operate(nexObj)
            % Apply opCfg (or identity), preserving the ptr handle reference
            % so UI callbacks bound at figure-build time remain valid.
            % isstruct() is intentionally avoided: DF_postOp can be a nexObj_DF
            % handle when the parent assigns its DF_postOp directly, making
            % isstruct() return false and triggering a new ptr — severing all
            % Window/Pointer UI closures that captured the original handle.
            savedPtr = [];
            try
                p = nexObj.DF_postOp.ptr;
                if isa(p, 'nexObj_ptr'), savedPtr = p; end
            catch
            end

            if ~isempty(nexObj.cfg.opCfg)
                opArgs           = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end

            % If DF_postOp is still a handle (e.g. Parent.DF_postOp is a
            % nexObj_DF), extract df+ax into a plain struct so we own our
            % own copy.  Without this, the Parent's next operate() would
            % overwrite .ptr on the shared handle, severing our UI closures.
            if ~isstruct(nexObj.DF_postOp)
                try
                    s.df = nexObj.DF_postOp.df;
                    s.ax = nexObj.DF_postOp.ax;
                    nexObj.DF_postOp = s;
                catch
                end
            end

            if ~isempty(savedPtr)
                nex_updateAxisPointer(savedPtr, nexObj.DF_postOp);
                nexObj.DF_postOp.ptr = savedPtr;
            else
                nexObj.DF_postOp.ptr = nexInit_axisPointer( ...
                    nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
            end
        end

        function updateScope(nexObj)
            if ~isempty(nexObj.Parent)
                nexObj.DF = nexObj.Parent.DF_postOp;
            end
            nexObj.operate();
            nexObj.visualize();
        end

        function buildFigure(nexObj)
            nexFigure_monoGram(nexObj);
        end

        function visualize(nexObj)
            nexVisualization_monoGram(nexObj, nexObj.cfg.visCfg.entryParams);
        end

        function applySRC(nexObj, srcKey)
            applySRC@nexObject(nexObj, srcKey);
            nexObj.visualize();
        end


    end
end
