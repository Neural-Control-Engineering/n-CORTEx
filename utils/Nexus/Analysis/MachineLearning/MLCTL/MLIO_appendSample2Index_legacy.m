function MLIO_appendSample2Index_legacy(fid, sampleAddress, DF_smp)
    addrFields = fieldnames(sampleAddress);   
    % ADDRESS VALS (e.g. unique IDs, sessionLabel, foldNum, curriculum
    fSize_index = ftell(fid);
    % start header if empty
    if fSize_index==0
        headerStruct = mergeStructs(sampleAddress, DF_smp.Y);
        headerStruct = mergeStructs(headerStruct, DF_smp.fitParams);
        headerFields = fieldnames(headerStruct);
        fprintf(fid,"fid_sample,");
        for i = 1:length(headerFields)
            hField = headerFields{i};
            fprintf(fid,"%s,",hField);
        end
        fprintf(fid,"\n");
    end
    % code, etc)
    for i = 1:length(addrFields)
        addrField = addrFields{i};
        addrVal = sampleAddress.(addrField);
        switch class(addrVal)
            case 'string'
                fprintf(fid,'%s,',addrVal)
            case 'double'
                fprintf(fid,'%d,',addrVal)
        end
        
    end
    % Y LABELS (optional)
    if ~isempty(DF_smp.Y)
        for i = 1:length(DF_smp.Y)
            fprintf(fid, '%d,', rowID);
            fprintf(fid, '%.6f,', values(1:end-1));
            fprintf(fid, '%.6f,', values(end));
        end
    end
    % Fit parameters Labels (optional)
    if ~isempty(DF_smp.fitParams)
        for i = 1:length(DF_smp.fitParams)

        end
    end  
    % start next line
    fprintf(fid,"\n");
end