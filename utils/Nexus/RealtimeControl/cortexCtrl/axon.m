function ax = axon(class)
    numCmds = numel(enumeration('ctrlKey'));
    bufferSize = 1000;
    maxDim = 3;
    switch class
        case "command"
            ax = Simulink.Bus;
            %% CMD
            elems(1) = Simulink.BusElement;
            elems(1).Name = 'CMD';
            elems(1).DataType = 'uint';
            elems(1).Dimensions = [numCmds,1];
            %% SZE
            elems(2) = Simulink.BusElement;
            elems(2).Name = 'SZE';
            elems(2).DataType = 'uint';
            elems(2).Dimensions = [numCmds, maxDim];
            %% PYD
            elems(3) = Simulink.BusElement;
            elems(3).Name = "PYD";
            elems(3).DataType = 'uint';
            elems(3).Dimensions = [numCmds, bufferSize];
            %% assembly
            ax.Elements = elems;           

        case "stream"            
            ax = Simulink.Bus;            
            %% SZE
            elems(1) = Simulink.BusElement;
            elems(1).Name = 'SZE';
            elems(1).DataType = 'uint';
            elems(1).Dimensions = [numCmds, maxDim];
            %% PYD
            elems(2) = Simulink.BusElement;
            elems(2).Name = "PYD";
            elems(2).DataType = 'uint';
            elems(2).Dimensions = [numCmds, bufferSize];
            %% assembly
            ax.Elements = elems;           
    end
end

% ax.CMD
% ax.SZE
% ax.PYD.signal_L
% ax.PYD.signal_M
% ax.PYD.tag
