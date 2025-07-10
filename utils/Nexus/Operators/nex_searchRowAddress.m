function dtsIdx = nex_searchRowAddress(DTS, rowAddr)
    if isempty(DTS)
        dtsIdx = [];
    else
        % try to find
        dtsCols = DTS.Properties.VariableNames;
        rowAddr_cell = struct2cell(rowAddr); 
        rowAddrFields_cell = fieldnames(rowAddr);
        dtsAddrCols = cellfun(@(addrField) DTS.(addrField), rowAddrFields_cell, "UniformOutput", false);
        % index location (return [] if not found)
        addrMatches = cellfun(@(addrCol, addrVal) (ismember(addrCol,addrVal)), dtsAddrCols, rowAddr_cell, "UniformOutput",true);
        idx_addrMatch = cellfun(@(addrCol, addrVal) find(ismember(addrCol,addrVal)), dtsAddrCols, rowAddr_cell, "UniformOutput",false);
        % addrMatches = cellfun(@(idx_match) idx_match==[], addrMatches,"UniformOutput",false);
        emptyCells = cellfun(@(idx) isempty(idx), idx_addrMatch, "UniformOutput",true);
        idx_addrMatch{emptyCells} = 0;
        idx_addrMatch = cell2mat(idx_addrMatch);
        if all(idx_addrMatch(:)== idx_addrMatch(1)) 
            dtsIdx = idx_addrMatch(1); % report index of alignment 
        else
            dtsIdx = []; % nothing aligned, nothing found            
        end
        
        

        
    end
end