function [ax, ax_struct] = axon_build(class)
    numCmds = numel(enumeration('ctrlKey'));
    numTgts = numel(enumeration('targetKey'));
    bufferSize = 10;
    maxDim = 3;

    elems = Simulink.BusElement.empty;  % initialize empty

    switch class
        case "command"
            ax = Simulink.Bus;

            elems(end+1) = makeElement('CMD', 'uint8', [numCmds, 1]);
            elems(end+1) = makeElement('SZE', 'uint8', [numCmds, maxDim]);
            elems(end+1) = makeElement('PYD', 'uint8', [numCmds, bufferSize]);

            ax.Elements = elems;
            ax_struct = buildStruct(ax);

        case "stream"
            ax = Simulink.Bus;

            elems(end+1) = makeElement('SZE', 'uint8', [numTgts, maxDim]);
            elems(end+1) = makeElement('PYD', 'uint8', [numTgts, bufferSize]);

            ax.Elements = elems;
            ax_struct = buildStruct(ax);
    end
end

function elem = makeElement(name, type, dims)
    elem = Simulink.BusElement;
    elem.Name = name;
    elem.DataType = type;
    elem.Dimensions = dims;
end

function s = buildStruct(busObj)
    % Builds a struct with zeros for each element, typed correctly
    s = struct();
    for i = 1:numel(busObj.Elements)
        elem = busObj.Elements(i);
        dims = num2cell(elem.Dimensions);  % ensure dims are individual scalars
        defaultVal = getDefaultValue(elem.DataType);
        s.(elem.Name) = cast(zeros(dims{:}), class(defaultVal));
    end
end

function val = getDefaultValue(dataType)
    % Returns a scalar of the correct data type
    switch dataType
        case 'double'
            val = 0;
        case 'single'
            val = single(0);
        case 'uint8'
            val = uint8(0);
        case 'uint16'
            val = uint16(0);
        case 'uint32'
            val = uint32(0);
        case 'uint64'
            val = uint64(0);
        case 'int8'
            val = int8(0);
        case 'int16'
            val = int16(0);
        case 'int32'
            val = int32(0);
        case 'int64'
            val = int64(0);
        case 'boolean'
            val = false;
        otherwise
            error(['Unsupported data type: ', dataType]);
    end
end
