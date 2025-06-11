function [ax, ax_struct] = axon_build_legacy(class)
    numCmds = numel(enumeration('ctrlKey'));
    numTgts = numel(enumeration('targetKey'));
    bufferSize = 10;
    maxDim = 3;
    switch class
        case "command"
            ax = Simulink.Bus;
            %% CMD
            elems(1) = Simulink.BusElement;
            elems(1).Name = 'CMD';
            elems(1).DataType = 'uint8';            
            elems(1).Dimensions = [numCmds,1];
            % elems(1).DimensionsMode = 'Variable';
            % elems(1).Value = zeros(numCmds,1);
            %% SZE
            elems(2) = Simulink.BusElement;
            elems(2).Name = 'SZE';
            elems(2).DataType = 'uint8';
            elems(2).Dimensions = [numCmds, maxDim];
            % elems(2).DimensionsMode = 'Variable';
            % elems(2).Value = zeros(numCmds,maxDim);
            %% PYD
            elems(3) = Simulink.BusElement;
            elems(3).Name = "PYD";
            elems(3).DataType = 'uint8';
            elems(3).Dimensions = [numCmds, bufferSize];
            % elems(3).DimensionsMode = 'Variable';
            % elems(3).Value = zeros(numCmds,bufferSize);
            %% assembly
            ax.Elements = elems;           

        case "stream"            
            ax = Simulink.Bus;            
            %% SZE
            elems(1) = Simulink.BusElement;
            elems(1).Name = 'SZE';
            elems(1).DataType = 'uint8';
            elems(1).Dimensions = [numTgts, maxDim];
            % elems(1).Value = zeros(numCmds,maxDim);
            % elems(1).DimensionsMode = 'Variable';
            %% PYD
            elems(2) = Simulink.BusElement;
            elems(2).Name = "PYD";
            elems(2).DataType = 'uint8';
            elems(2).Dimensions = [numTgts, bufferSize];
            % elems(2).Value = zeros(numCmds,bufferSize);
            % elems(2).DimensionsMode = 'Variable';
            %% assembly
            ax.Elements = elems;           
    end
end

% ax.CMD
% ax.SZE
% ax.PYD.signal_L
% ax.PYD.signal_M
% ax.PYD.tag
