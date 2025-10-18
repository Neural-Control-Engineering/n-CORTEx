function DF = nex_setAxisPointer(DF, axSel, axVal)
    % move selected axis pointers
    axFields = convertCharsToStrings(fieldnames(DF.ax));
    % axSel = axFields{dim};    
    if ~isfield(DF,"ptr")
        DF.ptr=struct;
        for i = 1:length(axFields)
            axField = axFields{i};
            DF.ptr.(axField)=1;
        end
    end
    DF.ptr.(axSel) = axVal;
end

% panFields = fieldnames(nexObj.Figure.panel2.editFields);
% for i = 1:length(panFields)
%     panField = panFields{i};
% 
%     fieldVal = nexObj.fitCfg.entryParams.(panField);
%     nexObj.Figure.panel2.editFields.(panField).uiField.Value = fieldVal;
% 
%     % fieldVal = nexObj.Figure.panel2.editFields.(panField).uiField.Value;
%     % nexObj.fitCfg.entryParams.(panField) = fieldVal;
% end