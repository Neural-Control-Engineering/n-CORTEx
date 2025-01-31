function nexPlayPause(animObj)
    switch animObj.isPlay
        case 1
            animObj.isPlay=0; % toggle
            start(animObj.pltTimer);            
        case 0
            animObj.isPlay=1;
            stop(animObj.pltTimer);            
    end
end