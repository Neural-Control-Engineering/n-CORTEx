function s = nex_createStructFromBusObj(busObj)
    % Generate a unique name for temporary bus assignment
    % tempName = ['tempBus_' char(java.util.UUID.randomUUID)];
    % tempName = strrep(tempName,"-","_");
    tempName = "busObj";
    % Assign the bus object to base workspace temporarily
    % assignin('base', tempName, busObj);

    % Create MATLAB struct
    s = Simulink.Bus.createMATLABStruct(tempName);

    % Clean up
    % evalin('base', ['clear ', tempName]);
end
