classdef nexObj_stateSpace < nexObject

    properties      
        STAT=[];
        STATE=[];
    end
    
    methods
        function nexObj = nexObj_stateSpace(nexon, Parent, Partner, STAT)
            % Inheritance
            nexObj = nexObj@nexObject(nexon, Parent, []);
            nexObj.classID = "stspc";
            %% Config structures                        
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_stateSpace"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexAnimate_stateSpace"));     
            nexObj.STAT=STAT;
            partnerID = Partner.classID;
            nexObj.Partners.(partnerID)=Partner;
            nexFigure_stateSpace(nexObj);
        end       

        function joinSamplesByGroup(nexObj)
            % update STAT table
            nexObj.STAT=nexObj.Partners.ctg.STAT;
            % compose joint samples
            groupIDCols=["sessionLabel_subj"];
            nexObj.STATE = nexOp_fuseGroups(nexObj.STAT, groupIDCols);
        end

        function visualize(nexObj)
            visArgs=nexObj.cfg.visCfg.entryParams;
            nexVisualization_stateSpace(nexObj, visArgs);
        end

    end
end