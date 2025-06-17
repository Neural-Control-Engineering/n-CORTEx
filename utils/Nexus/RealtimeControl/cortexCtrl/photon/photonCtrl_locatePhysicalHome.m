function photonCtrl_locatePhysicalHome(proxObj)
    z_top = -40000;
    z_bottom = 0;
    % drive to upper limit
    proxObj.Server.SendScriptCommands(sprintf('-ma Z %d True',z_top));
    % proxObj.Server.SetMotorPosition(sprintf('Z %d',z_top));
    % drive to floor (z=0)
    proxObj.Server.SendScriptCommands(sprintf('-ma Z %d True',z_bottom));
    % enable next sequence
    controlPanel = proxObj.controlPanel;    
    controlPanel.Figure.updatePositionButton.Enable="on";   
    controlPanel.Figure.resetPositionButton.Enable="on";    
    controlPanel.Figure.initializeMicroscope.Enable="off";    
end