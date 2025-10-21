function nex_updatePartners(nexObj)
    if ~isempty(nexObj.Partners)
        nexObjPartnerList = fieldnames(nexObj.Partners);
        for i = 1:length(nexObjPartnerList)
            nexObjPartnerName = nexObjPartnerList{i};
            nexObjPartner = nexObj.Partners.(nexObjPartnerName);
            nexObjPartner.DF = nexObj.DF_postOp;
            % run update method            
            try
                nexObjPartner.updateScope(nexObj.nexon);
            catch e
                try
                    nexObjPartner.updateScope();
                catch e                   
                    disp(getReport(e));
                end
            end
        end
    end
end