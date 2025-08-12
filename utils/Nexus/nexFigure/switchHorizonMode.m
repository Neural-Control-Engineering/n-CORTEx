function switchHorizonMode(nexon, spectroGram, bandPool)    
    switch bandPool.UserData.horizonButton.UserData.state
        case 0 % activate horizon
            bandPool.UserData.horizonButton.BackgroundColor = nexon.settings.Colors.cyberGreen;
            bandPool.horizon(nexon,spectroGram);
            bandPool.UserData.horizonButton.UserData.state=1;
        case 1 % deavtivate horizon
            bandPool.UserData.horizonButton.BackgroundColor = [0,0,0];
            bandPool.deHorizon(nexon,spectroGram);
            bandPool.UserData.horizonButton.UserData.state=0;
    end
end