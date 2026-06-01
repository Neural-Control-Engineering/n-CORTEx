classdef nexObj_stateSpace < nexObject

    properties      
        STAT=[];
        STATE=[];    
        AVG
    end
    
    methods
        function nexObj = nexObj_stateSpace(nexon, Parent, Partner)
            % Inheritance
            nexObj = nexObj@nexObject(nexon, Parent, []);
            nexObj.classID = "stspc";
            %% Config structures                        
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_stateSpace"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexAnimate_stateSpace"));     
            nexObj.STAT=Partner.STAT;
            partnerID = Partner.classID;
            nexObj.Partners.(partnerID)=Partner;
            nexFigure_stateSpace(nexObj);
        end       

        function joinSamplesByGroup(nexObj)
            % update STAT table
            nexObj.STAT=nexObj.Partners.ctg.STAT;
            % compose joint samples
            groupIDCols=["sessionLabel_subj"];
            nexObj.STAT = nexOp_fuseGroups(nexObj.STAT, groupIDCols);
        end

        function visualize(nexObj)
            visArgs=nexObj.cfg.visCfg.entryParams;
            % pseudo-selection
            nexObj.collector.AVG=["sessionLabel_phase"]; % average by these groups
            % nexObj.collector.VW=["L-hind-paw","L-hind-paw-CCI"]; % view these groups
            nexObj.collector.VW=["L-hind-paw","L-hind-paw-CCI","R-hind-paw-CCI","R-hind-paw"]; % view these groups
            nexObj.collector.CLR=["sessionLabel_phase"]; % color by phase
            nexVisualization_stateSpace(nexObj, visArgs);
        end

        function reportAverage(nexObj)
            % nexObj.STATE = nexObj.Partners.ctg.STAT;
            % average within selected groups
            STAT = nexObj.STAT;            
            % trim
            dfCol = nexOp_trimDfCol(STAT.df);
            STAT.df=dfCol(:);
            % tf=cat(3,dfCol{:});
           [G, groupNames] = findgroups(STAT.(nexObj.collector.AVG));    
           catDim = ndims(dfCol{1})+1;
           STAT_avg = splitapply(@(tf) {mean(cat(catDim,tf{:}), catDim)}, STAT.df, G);
           AVG.df=STAT_avg;
           % AVG.ax=STAT.ax; % !!!
           AVG.(nexObj.collector.AVG) = groupNames;
           T_AVG = struct2table(AVG);
           % tCond=[1600:2250]; % TEMP
           tCond=[600:2250]; % TEMP
           % tCond=[1750:2150]; % TEMP
           T_AVG.df = cellfun(@(df) df(tCond,:), T_AVG.df,"UniformOutput",false); % TEMP
           nexObj.AVG = T_AVG;
            % STATE_avg = splitapply( ...
            %     @(c) mean(cat(1,c{:}),1), ...
            %     STATE.df, ...
            %     G);
        end

        function STATE = buildSTATE(nexObj)
            % compile AVG, DF, and/or STAT 
            %% AVG
            % Z_AVG = cat(1, nexObj.AVG.df{:});            
            % G_AVG = [];
            % S_AVG = [];
            [Z_AVG, G_AVG, S_AVG] = nexOp_stackSTAT(nexObj.AVG);
            %% DF
            if ~isempty(nexObj.DF)
                try
                    Z_DF = nexObj.DF.df;
                    G_DF = dtsIO_categorizeDF(nexon, DF);
                    S_DF = zeros(size(Z_DF));
                catch e
                    disp(getReport(e));
                    Z_DF=[];
                    G_DF=[];
                    S_DF=[];
                end
            else
                Z_DF=[];
                G_DF=[];
                S_DF=[];
            end                    
            %% STAT
            try
                [Z_STAT, G_STAT, S_STAT] = nexOp_stackSTAT(nexObj.STAT);
            catch e
                disp(getReport(e));
                Z_STAT=[];
                G_STAT=[];
                S_STAT=[];
            end
            % STATE.Z = [Z_AVG; Z_DF; Z_STAT]; % N-dimensional                       
            % STATE.G = [G_AVG; G_DF; G_STAT]; % grouping
            % STATE.S = [S_AVG; S_DF; S_STAT]; % size
            STATE.Z = [Z_AVG; Z_DF]; % N-dimensional                       
            STATE.G = [G_AVG; G_DF]; % grouping
            STATE.S = [S_AVG; S_DF]; % size
        end

        function STATE = filterSTATE(nexObj)

        end

    end
end