classdef nexObj_controlPanel_npxls < handle
    properties
        nexon
        nCORTEx
        proxon
        Children
        Parents
        Partners
        Figure        
    end
    methods
        function nexObj = nexObj_controlPanel_npxls(nexon, nCORTEx)
            % nexObj.nexon = nexon;
            nexObj.nCORTEx = nCORTEx;
            nexObj.nexon=nCORTEx.nexon;
            nexObj.proxon = nCORTEx.proxon;
            nexFigure_controlPanel_npxls(nexObj);
        end
    end
end