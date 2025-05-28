function spt = pv_readSPF(filePath)
    % Reads a .xy XML file into a MATLAB table
    xDoc = xmlread(filePath);
    nodes = xDoc.getElementsByTagName('StageLocation');

    numNodes = nodes.getLength;
    data = [];

    for k = 0:numNodes-1
        node = nodes.item(k);
        attrs = node.getAttributes;
        row = struct();
        for a = 0:attrs.getLength-1
            attr = attrs.item(a);
            key = char(attr.getName);
            val = char(attr.getValue);

            % Try to convert numeric strings to doubles
            numVal = str2double(val);
            if ~isnan(numVal)
                row.(key) = numVal;
            else
                row.(key) = val;
            end
        end
        data = [data; row];
    end

    spt = struct2table(data);
end
