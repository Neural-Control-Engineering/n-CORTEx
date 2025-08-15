function AVG = dtsIO_readAVG(nexObj, ptr_dts)
    if isstruct(ptr_dts) % find matching struct
        ptr_dts = rmfield(ptr_dts,"phase");
        ptr_dts = rmfield(ptr_dts,"date");
        idx_match = arrayfun(@(row) compareArgs(row, ptr_dts), nexObj.UserData.T_avg.("avgCfg"));
        AVG = nexObj.UserData.T_avg(idx_match,"AVG").AVG{1,1};
    elseif isnumeric(ptr_dts) % index T_avg at index
        AVG = nexObj.UserData.T_avg(ptr_dts,"AVG").AVG{1,1};    
    end
end