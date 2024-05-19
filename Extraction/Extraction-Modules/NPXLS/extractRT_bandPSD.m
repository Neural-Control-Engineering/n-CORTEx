function extractRT_bandPSD(sgSrv, modSrv, bands)
    data =  FetchLatest(modSrv, 2, 0, 2000); 
    lfp = data(:,385:768);
    PSD = extractBandPSD(lfp, bands);
    % figure; imagesc(cell2mat(PSD));
    % set(gcf,"Position",[487,43,120,1759]);
    % SEND OVER TCP
    PSD = cell2mat(PSD);
    for i = 1:size(PSD,2)
        bandData = uint8(PSD(:,i));
        write(sgSrv,bandData);
    end

    
end