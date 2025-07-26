classdef nexObj_spectroGraph_specs < handle
    properties
        classID="spgphSP"
        nexon
        Origin
        Parent
        preBuffLen=3.5
        DF
        DF_postOp
        dfID_source
        dfID_target
        opCfg=struct;
        visCfg=struct;
        Figure
        UserData=struct;
        chanSel=1;
        freqSel=1;
    end
    methods
        function nexObj = nexObj_spectroGraph_specs(nexon, Parent, DF, opFcn, visFcn)
            % nexObj.Origin = Parent.Origin;
            nexObj.Origin = Parent;
            if isempty(nexon)
                nexObj.nexon = nexObj.Origin.nexon;            
            else
                nexObj.nexon=nexon;
            end
            nexObj.Parent=Parent;
            if isempty(DF)
                nexObj.DF = nexObj.Parent.DF_postOp;
            else
                nexObj.DF = DF;
            end
            nexObj.DF_postOp.df=[];
            nexObj.DF_postOp.ax=[];
            nexObj.dfID_source=nexObj.Parent.dfID_target;
            if isempty(visFcn)
                visFcn=str2func("nexVisualization_spectroGraph_specs");
            end
            if isempty(opFcn)
                % nexObj.DF_postOp = nexObj.DF;                
            end
            nexObj.visCfg=extractCfg(visFcn);
            nexObj.visCfg.visFcn=visFcn;
            nexFigure_spectroGraph_specs(nexObj);
            % add to nexObjs list
            nexObj.nexon.console.BASE.nexObjs.(sprintf("%s_1",nexObj.classID)) = nexObj;
        end

        function updateScope(nexObj)
            nexUpdate_spectroGraph_specs(nexObj);
        end
    end
end