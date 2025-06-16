function poolMap = extractPoolMap(nexObj)
    poolCfgPanel = nexObj.Figure.poolCfgPanel;
    % get selected args
    axPoolFields = convertCharsToStrings(fieldnames(poolCfgPanel));
    axPoolFields = axPoolFields(contains(axPoolFields,"label"));
    for i = 1:length(axPoolFields)
        axPoolField = axPoolFields{i};
        axPoolField = strrep(axPoolField,"_label","");
        dropDownID = sprintf("%s_dropDown",axPoolField);
        spinnerID = sprintf("%s_spinner",axPoolField);
        poolTypeSel = poolCfgPanel.(dropDownID).Value;
        % keyWord search
        if strcmp(poolTypeSel,"bands")
            poolMap.f = [];
        elseif strcmp(poolTypeSel,"regions")
        else
        end
    end
    % special selection cases 
end

% x = rand(1, 1000);              % data to average
% x = [1:10];
% edges = [0, 2, 5, 7, 10];  % custom bin edges
% 
% % Assign each data point to a bin
% binIDs = discretize(x, edges);