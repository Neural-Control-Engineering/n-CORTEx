function out = readDataMod(modServer, bufferSize)
    modType = class(modServer);
    switch modType
        case "SpikeGL"
            out = FetchLatest(modServer, 2, 0, bufferSize);  % max_samps = bufferSize
        case "PLink"
        otherwise
            out = [];
            fprintf("ERROR: modality of type %s not recognized",modType)
    end
end