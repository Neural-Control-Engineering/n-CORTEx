classdef nexObj_pixelGram < handle
    properties
        classID = "pxg"
        nexon
        dfID_source        
        DF
        dfID_target
        DF_postOp
        Figure
        Parent
        Partners
        Origin        
        Children
        player
        cfg = struct        
    end

    methods
        function nexObj = nexObj_pixelGram(Partner, nexon)
            % visualize along the grid of a neuropixels probe : firing
            % rates, lfps, ...
            nexObj.nexon = nexon;
            %% Add as Partner
            nexObj.Partners.(Partner.classID) = Partner;
            Partner.Partners.(nexObj.classID) = nexObj;
            nexObj.Origin = Partner;
            % nexObj.Parent.Children.(nexObj.classID) = nexObj;
            %% Config structures
            % nexObj.cfg.opCfg = nex_generateCfgObj();
            nexObj.cfg.opCfg=[];
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_pixelGram"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexAnimate_pixelGram"));                 %% DF
            nexObj.DF = Partner.DF;
            nexObj.operate();
            nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
            %% Build Figure
            nexObj.buildFigure();
            % animation player
            nexObj.player = timer('Period',0.2,'BusyMode','drop','TimerFcn',@(~,~) nexObj.animate(),"ExecutionMode","fixedRate");


        end

        function buildFigure(nexObj)
           nexFigure_pixelGram(nexObj);
        end

        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            nexVisualization_pixelGram(nexObj, visArgs);
        end

        function updateScope(nexObj)      
            % inherit DF from parent OR from DTS
            % nexObj.DF = nexObj.Parent.DF;
            % nexObj.DF = nexObj.Partner
            nexObj.operate();
            % visualize results
            nexObj.visualize();
        end

        function startPlayer(nexObj)
            isPlay = nexObj.Figure.playButton.Value;
            switch isPlay
                case 0 % "start animation"
                    % nexObj.Figure.playButton.Value=1; % remember state
                    nexObj.player.start;
                case 1 % "stop/pause animation"
                    % nexObj.Figure.playButton.Value=0; % remember state
                    nexObj.player.stop;
            end
        end

        function animate(nexObj)
            aniArgs = nexObj.cfg.aniCfg.entryParams;
            nexAnimate_pixelGram(nexObj, aniArgs);
        end

        function operate(nexObj)
            if isfield(nexObj.DF_postOp,'ptr')
                oldPtr = nexObj.DF_postOp.ptr;
            else
                oldPtr = [];
            end
            if ~isempty( nexObj.cfg.opCfg)
                opArgs = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end            
            % preserve ptrObj
            if ~isempty(oldPtr)
                nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
                newPtr = nexObj_ptr(nexObj.DF_postOp.ptr);
                f = fieldnames(newPtr);
                for i = 1:numel(f)
                    oldPtr.(f{i}) = newPtr.(f{i});
                end
                nexObj.DF_postOp.ptr = oldPtr;
            end            
        end
    end
end