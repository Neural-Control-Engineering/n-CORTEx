function pMap = nexInit_pMap(nexObj, DF)
    % for each ax, preload a pool map object (try to use pre-existing
    % functions by the prototype: poolMap_<ax>.m
    nexon = nexObj.nexon;
    axFields = fieldnames(DF.ax);
    for i = 1:length(axFields)
        axField = axFields{i};
        % temporary conditionals 
        if strcmp(axField,'t')
            axField_label = "time";
            % Map = derive_pMap_time(nexon, DF);
            events = dtsIO_listEvents(nexon);
            Map = map_events2time(events);
            mapID = "event";
        elseif strcmp(axField,'f')
            axField_label = "freqs";
            bands = nexon.console.BASE.params.bands;
            Map = map_bands2freqs(bands);
            mapID = "band";
        elseif strcmp(axField, "chans")
            axField_label = "chans";
            regMap = nexon.console.NPXLS.shanks.shank1.regMap;
            Map = map_regions2chans(regMap);
            mapID = "region";
        else
            return
        end
        prototype = str2func(sprintf("nexObj_poolMap_%s",axField_label));
        pMap.(axField) = prototype(nexObj, Map, [], axField_label, mapID);
        pMap.(axField).axSel=axField;
    end
end