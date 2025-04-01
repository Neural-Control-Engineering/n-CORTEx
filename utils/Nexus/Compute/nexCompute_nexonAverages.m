function nexCompute_nexonAverages(nexon, selIdx)
    nexObjFields = fieldnames(nexon.console.BASE.nexObjs);
    for i = 1:length(nexObjFields)
        nexObjField = nexObjFields{i};
        nexObj = nexon.console.BASE.nexObjs.(nexObjField);
        if ismethod(nexObj,"reportAverage")
            nexObj.reportAverage(selIdx);
        end
    end

end