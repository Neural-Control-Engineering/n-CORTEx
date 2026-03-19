classdef nexObj_monoGram < nexObject
    % nexObj_monoGram  2-D visualization object, parallel to nexObj_monoGraph.
    % Renders factor data (F) across two display dimensions (D1 × D2) using
    % surf, enabling both flat image and pseudo-3D views. An animation player
    % steps through whichever axis is assigned as domain.animate.
    %
    % Terminology
    %   F        : factor axis  – output features (CEBRA dims, freq bins, PCA comps, ...)
    %   D1       : primary display dimension(s)  (channels, trials, ...)
    %   D2       : secondary / animation dimension(s)  (time, trials, ...)
    %   animate  : the single ax key currently driven by the player timer
    %   display.rows / .cols : ax keys mapped to surf YData / XData
    %
    % Constructor
    %   nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain)
    %     nexon       – Nexon handle  (ignored when Parent provided)
    %     Parent      – parent nexObj  (pass [] for standalone use)
    %     dfID_source – DTS column prefix; DF loaded via dtsIO_readDF
    %     opCfgFcn    – function handle for op  (pass [] for identity)
    %     domain      – domain struct override  (pass [] to auto-infer)

    properties  
    end

    methods

        % ── Constructor ───────────────────────────────────────────────────
        function nexObj = nexObj_monoGram(nexon, Parent, dfID_source, opCfgFcn, domain)
            % resolve nexon before superclass call (no object access allowed yet)
            if ~isempty(Parent)
                nexon = Parent.nexon;
            end
            nexObj = nexObj@nexObject(nexon, Parent, dfID_source);
            nexObj.classID = "mgm";

            %% DF loading
            if ~isempty(Parent)
                nexObj.DF       = Parent.DF_postOp;
                nexObj.Origin   = Parent.Origin;
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

            %% Operate → DF_postOp
            nexObj.operate();

            %% Axis pointer
            nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);

            %% Pool map
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end

            %% Domain
            if nargin >= 5 && ~isempty(domain)
                nexObj.domain = domain;
            else
                nexObj.domain = nexObj.inferDomain();
            end

            %% Figure
            nexObj.buildFigure();

            %% Animation player
            nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
        end

        % ── Core pipeline ─────────────────────────────────────────────────
        function operate(nexObj)
            % Apply opCfg (or identity), preserving the ptr handle.
            %
            % The ptr handle must be saved BEFORE DF_postOp is replaced,
            % then updated in-place and re-attached. Replacing it with a new
            % nexObj_ptr object would orphan UI callbacks (axisPtrChanged etc.)
            % that captured the original handle by reference at figure-build time.
            if isstruct(nexObj.DF_postOp) && isfield(nexObj.DF_postOp, 'ptr') ...
                    && isa(nexObj.DF_postOp.ptr, 'nexObj_ptr')
                savedPtr = nexObj.DF_postOp.ptr;   % save handle reference
            else
                savedPtr = [];
            end

            if ~isempty(nexObj.cfg.opCfg)
                opArgs = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.fcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end

            if ~isempty(savedPtr)
                % Update existing handle in-place (preserves callback bindings),
                % then re-attach to the new DF_postOp struct.
                nex_updateAxisPointer(savedPtr, nexObj.DF_postOp);
                nexObj.DF_postOp.ptr = savedPtr;
            else
                nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
            end
        end

        function updateScope(nexObj)
            if ~isempty(nexObj.Parent)
                nexObj.DF = nexObj.Parent.DF_postOp;
            end
            nexObj.operate();
            nexObj.visualize();
        end

        % ── Visualization & animation ─────────────────────────────────────
        function buildFigure(nexObj)
            nexFigure_monoGram(nexObj);
        end

        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            nexVisualization_monoGram(nexObj, visArgs);
        end

        function animate(nexObj)
            nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams);
        end

        function startPlayer(nexObj)
            % Toggle the player timer from a UI button.
            % Expects nexObj.Figure.playButton with .Value (0=stopped, 1=playing)
            isPlay = nexObj.Figure.playButton.Value;
            switch isPlay
                case 0
                    nexObj.player.start;
                case 1
                    nexObj.player.stop;
            end
        end

        % ── Averaging ─────────────────────────────────────────────────────
        function reportAverage(nexObj, idxSel)
            %% RETRIEVAL
            TF = nexOp_compileTF(nexObj, idxSel);
            %% COMPUTE RESULT
            ptr = nexObj.DF_postOp.ptr;
            DF_avg = nexOp_averageTF(TF, ptr, 2);
            DF_avg.ptr    = ptr;
            DF_avg.avgCfg = nexTract_avgCfg(nexObj.nexon);
            %% STORE
            nexObj.DF_postOp = DF_avg;
            nex_storeAverage(nexObj, nexObj.DF_postOp);
            %% VISUALIZE
            nexObj.visualize();
        end

    end
end
