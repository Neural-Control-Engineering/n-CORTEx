function nexUpdate_DfID(nexon, modality, newDfID, prevDfID)
    switch modality
        case "NPXLS"
            shankList = fieldnames(nexon.console.NPXLS.shanks);
            for i = 1:length(shankList)
                shankID = shankList{i};
                scopeFields = fieldnames(nexon.console.NPXLS.shanks.(shankID).scope);
                for j=1:length(scopeFields)
                    scopeField = scopeFields{j};
                    if isempty(prevDfID)
                        nexon.console.NPXLS.shanks.(shankID).scope.(scopeField).dfID = newDfID;
                    else
                        if nexon.console.NPXLS.shanks.(shankID).scope.(scopeField).dfID == prevDfID
                            nexon.console.NPXLS.shanks.(shankID).scope.(scopeField).dfID = newDfID;
                        end
                    end
                end
            end
        case "SLRT"

    end
end