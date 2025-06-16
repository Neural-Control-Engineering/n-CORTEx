function generateAxonDataDict()
    Simulink.data.dictionary.closeAll('-discard')
    dictName = 'dictionary_axon.sldd';
    if exist(dictName, 'file')
        delete(dictName);  % overwrite if needed
    end
    
    dictObj = Simulink.data.dictionary.create(dictName);
    dDataSect = getSection(dictObj, 'Design Data');
    cls_abv = ["CMD","STM"];
    i=1;
    for cls = ["command", "stream"]
        axonBus = axon_build(cls);                     % Build the bus object
        busName = "axon_" + cls;
        defaultName = busName + "_default";
        defaultValName = sprintf("axon_%s",cls_abv(i));
        % defaultValName = sprintf("axon_STM")

        % Register the bus object in the dictionary
        addEntry(dDataSect, busName, axonBus);

        % Create the default struct from the BUS NAME, not the object
        % Simulink.Bus.cellToObject({busName, axonBus});
        assignin("base","axonBus",axonBus);
        defaultStruct = Simulink.Bus.createMATLABStruct("axonBus");

        % Wrap in a Simulink.Parameter object
        param = Simulink.Parameter;
        param.Value = defaultStruct;
        param.DataType = "Bus: " + busName;
        param.CoderInfo.StorageClass = 'ExportedGlobal';
        param.Description = "Default value for " + busName;

        % Add the parameter to the dictionary
        addEntry(dDataSect, defaultValName, param);
        % addEntry(dDataSect,defaultValName, defaultStruct);
        % Add size parameter to the dictionary
        switch cls
            case "command"
                len_ctx_tx = size(defaultStruct.CMD,1) * (1+size(defaultStruct.SZE,2)+size(defaultStruct.PYD,2));
                paramID = sprintf("len_ctx_tx_%s",cls_abv(i));
            case "stream"
                len_ctx_tx = size(defaultStruct.PYD,1) * (size(defaultStruct.SZE,2)+size(defaultStruct.PYD,2));
                paramID = sprintf("len_ctx_tx_%s",cls_abv(i));
        end
        
        addEntry(dDataSect, paramID, len_ctx_tx);
        i=i+1;
    end

    saveChanges(dictObj);    
    Simulink.data.dictionary.closeAll('-save')
    close(dictObj);
    disp("Data dictionary created: " + dictName);
end
