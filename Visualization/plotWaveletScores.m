function plotWaveletScores(PRE, POST, P, phase, event)
    if isempty(phase)
        phase="";
    end
    if isempty(event)
        event = "";
    end
    fh = figure;
    t1 = tiledlayout(1,3);
    title(t1,sprintf("%s--%s",phase, event));
    tAx = nexttile(t1); 
    % imagesc(mean(PRE,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    imagesc(mean(PRE,3)); caxis(tAx,[-50.56459709605963,-42.346166098559635]);
    title(tAx,"PRE")    
    tAx = nexttile(t1); 
    % imagesc(mean(POST,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    imagesc(mean(POST,3)); caxis(tAx,[-50.56459709605963,-42.346166098559635]);
    title(tAx,"POST")    
    tAx = nexttile(t1); 
    imagesc(mean(POST,3)-mean(PRE,3)); caxis(tAx,[-0.5357779729561683,0.89297928765196])        
    title(tAx,"DIFF")
end