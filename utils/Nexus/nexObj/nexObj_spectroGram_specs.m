classdef nexObj_spectroGram_specs < handle
    properties
        classID="spgSP"
        nexon
        Origin
        Parent
        Children
        DF
        DF_postOp
        dfID_source
        dfID_target
        opCfg
        visCfg
        Figure
        UserData
    end
    methods
        function nexObj = nexObj_spectroGram_specs(nexon, Parent, DF, opFcn, visFcn)
            if isempty(nexon)
                nexObj.nexon = nexon;
            else
                nexObj.nexon = Parent.nexon;                
            end
            nexObj.Parent = Parent;
            nexObj.DF=DF;
        end
    end
end