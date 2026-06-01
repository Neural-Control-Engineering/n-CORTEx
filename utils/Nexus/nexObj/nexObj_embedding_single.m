classdef nexObj_embedding_single < handle
    properties
        classID="emb1"
        DF
        DF_postOp
        mlObj
        dfID_source
        nexon
        Parent
        Partners
        Figure
        cfg = struct
        UserData=struct()
        frameNum=1
        player
    end

    methods
        function nexObj = nexObj_embedding_single(Partner, mlObj)
            nexObj.nexon = Partner.nexon;
            nexObj.mlObj = mlObj;
            Partner.Partners.(nexObj.classID) = nexObj;
            nexObj.Partners.(Partner.classID) = Partner;
            %% Config structures                        
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_embedding_single"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexAnimate_embedding_single"));     
            %% DF
            nexObj.DF = Partner.DF_postOp;
            nexObj.operate();
            %% Build Figure
            nexFigure_embedding_single(nexObj);
            % animation player
            nexObj.player = timer('Period',0.1,'BusyMode','drop','TimerFcn',@(~,~) nexObj.animate(),"ExecutionMode","fixedRate");
        end

        function operate(nexObj)
            df_in = nexObj.DF.df; % X
            df_in = df_in'; % transpose assuming time dim is 2
            % transform (using embedding)
            df_tf = nexObj.mlObj.transform(df_in);
            nexObj.DF_postOp.df = df_tf; % Z
            nexObj.DF_postOp.ax = nexObj.DF.ax;
        end
        
        function updateScope(nexObj)
            % operate on partner-inherited DF
            nexObj.operate();
            % visualize results
            nexObj.visualize();            
        end

        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            % nexVisualization_embedding_single(nexObj, visArgs);
            nexObj.cfg.visCfg.fcn(nexObj, visArgs);
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
            % disp(0)
            aniArgs = nexObj.cfg.aniCfg.entryParams;
            % try
            nexAnimate_embedding_single(nexObj, aniArgs);
            % catch e
            %     disp(getReport(e));
            %     keyboard
            % end
        end

        % function getVal
        % end
    end
end