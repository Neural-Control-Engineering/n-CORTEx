function nexSelect_Y(nexObj)
    % prepare a dictionary for a label bus selection
    dict = struct;
    % fieldnames of DTS
    % sessionLabel tags
    buildSelection(nexObj, dict);
end