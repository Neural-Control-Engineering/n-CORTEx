
function extractRT_bandPSD(sgSrv, modSrv)
    data =  FetchLatest(modSrv, 2, 0, 2000); 
    lfp = data(:,385:768);
    parfor i = 1:size(lfp,2)-1
        bandPower = 
    end
end