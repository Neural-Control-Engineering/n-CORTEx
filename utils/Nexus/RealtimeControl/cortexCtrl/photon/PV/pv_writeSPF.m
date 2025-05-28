function pv_writeSPF(filePath, spt)
    % Writes the MATLAB table back to .xy XML format
    docNode = com.mathworks.xml.XMLUtils.createDocument('StageLocations');
    stageLocations = docNode.getDocumentElement;

    for i = 1:height(spt)
        stageNode = docNode.createElement('StageLocation');
        vars = spt.Properties.VariableNames;

        for v = 1:numel(vars)
            key = vars{v};
            val = spt{i,v};

            if isnumeric(val)
                attrVal = num2str(val, '%.15g');  % dynamic formatting
            else
                attrVal = char(val);
            end

            stageNode.setAttribute(key, attrVal);
        end
        stageLocations.appendChild(stageNode);
    end

    xmlwrite(filePath, docNode);
end
