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
            % "epoch" is now the default mapID for t (not "event") --
            % Nexus WIP.md #16. Map is left empty here deliberately:
            % nexObj_poolMap.getBinEdges's mapID=="epoch" branch calls
            % map_epochs2time(axis, epochWidthProportion) FRESH on its
            % own `axis` argument every time it's actually needed --
            % trial-specific boundaries can't be precomputed once at
            % construction the way region/band/event's static Map can --
            % so it never reads poolMap.Map for this scheme at all. This
            % also means event's own construction (dtsIO_listEvents +
            % map_events2time) is skipped entirely now, not just unused --
            % one less DTS read per construction.
            % Map = derive_pMap_time(nexon, DF);
            % events = dtsIO_listEvents(nexon);
            % Map = map_events2time(events);
            % mapID = "event";
            Map   = [];
            mapID = "epoch";
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
            continue
        end
        prototype = str2func(sprintf("nexObj_poolMap_%s",axField_label));
        pMap.(axField) = prototype(nexObj, Map, [], axField_label, mapID);
        pMap.(axField).axSel=axField;
        if mapID == "epoch"
            % Required by map_epochs2time.m -- errors outright if left
            % empty. Default only; edit directly via
            % pMap.t.epochWidthProportion after construction.
            pMap.(axField).epochWidthProportion = 0.2;
        end
    end
end