function photonCtrl_moveToPos(proxObj, idx_pos)        
    % clear current positions
    proxObj.Server.sendScriptCommands('spc');
    % load xy file 
    proxObj.Server.sendScriptCommands('lspf');
    % index position coordinates (idx=1) &    
    % move to position (throw error if invalid)
    proxObj.Server.sendScriptCommands(sprintf('mtsp %d', idx_pos));
end