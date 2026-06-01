classdef nexObject < handle

    properties
        classID
        Parent
        Partners
        Children
        Origin
        nexon
        DF
        dfID_source
        DF_postOp
        dfID_target
        collector
        domain
        pointer
        Figure
        UserData
        cfg=struct
    end

    methods
        function nexObj = nexObject(nexon, Parent, dfID_source)
            nexObj.nexon = nexon;
            nexObj.Parent = Parent;
            nexObj.dfID_source = dfID_source;
        end
    end

end