function photonCtrl_moveToPos(proxObj, idx_pos, filePath)        
    % clear current positions
    proxObj.Server.SendScriptCommands('-spc');
    % load xy file 
    proxObj.Server.SendScriptCommands(sprintf('-lspf %s', filePath));
    % index position coordinates (idx=1) &    
    % move to position (throw error if invalid)
    proxObj.Server.SendScriptCommands(sprintf('-mtsp %d', idx_pos));
end