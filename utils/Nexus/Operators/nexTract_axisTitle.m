function  axTitle = nexTract_axisTitle(nexObj, DF, dimList)
    % identify variables (primary, secondary dims, factors)
    domain = nexObj.domain;
    % build axis title from pointer dim/val, poolMap. and secondary dimensions
    if nargin < 3 || isempty(dimList)
        dimList = domain.D2;
    else
        dimList = dimList;
    end
    % pMap = nexObj.pMap;
    ptr=DF.ptr;
    axTitle="";
    for i = 1:length(dimList)
        d = dimList(i);
        % pm=pMap.(d);
        % binType=pm.binType;
        binIdx=ptr.(d).value;
        % binIDs=DF.ax.(d);
        try
            binIDs=DF.labels.(d);
        catch e
            % disp(e);
            binIDs=DF.ax.(d);
        end
        binID=binIDs(binIdx);
        switch class(binID)
            case"string"
                axTitle = strcat(axTitle, d, ':',{' '}, binID);
            case "double"
                axTitle = strcat(axTitle, d, ':', {' '}, num2str(binID));
        end
        if i ~=length(dimList)
            axTitle=strcat(axTitle, ' |');
        end
        
    end

end