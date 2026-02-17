function  nexInit_registry(nexon)
    categories_sessionLabel = nexOp_listCategories_sessionLabel(nexon);
    % itemize each category
    %% SESSION LABEL
    for i = 1:length(categories_sessionLabel)
        sessionLabelKey = categories_sessionLabel(i);
        sessionLabelKey_parts = split(sessionLabelKey,"--");
        sessionLabelKey_part = sessionLabelKey_parts(end);
        items = parseSessionLabelUnique(nexon.console.BASE.DTS.sessionLabel, sessionLabelKey_part);
        nexon.console.BASE.registry.categories.(strrep(sessionLabelKey_part,"--","_")) = items;
    end
    %% SIGNAL TYPES
    categories_signalTypes = nexOp_listCategories_signals(nexon);
    for i = 1:length(categories_signalTypes)
        signalKey = categories_signalTypes(i);
        signalKey_parts = split(signalKey,"--");
        signalKey_part = signalKey_parts(end);
        signalVals = unique(nexon.console.BASE.DTS.(signalKey_part));
        nexon.console.BASE.registry.categories.(signalKey_part) = signalVals;
    end
    %% MAPS
end

% res=cellfun(@(df) (df==9.669406058356351), rThresh,"UniformOutput",false)
% isEmp=cellfun(@(r) (r==1), res, "UniformOutput",true);
% res(isEmp==1)=num2cell(0);
% res_final = (cat(1,res(:)));
