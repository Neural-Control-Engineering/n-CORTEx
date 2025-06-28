function nexCompute_nexonAverages(nexon, selIdx)
    nexObjFields = fieldnames(nexon.console.BASE.nexObjs);
    for i = 1:length(nexObjFields)
        nexObjField = nexObjFields{i};
        nexObj = nexon.console.BASE.nexObjs.(nexObjField);
        if ismethod(nexObj,"reportAverage")
            try
                nexObj.reportAverage(selIdx);
            catch e
                disp(getReport(e))
            end
        end
    end

end