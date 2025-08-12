function nexusCtrl_startNexus(proxObj)
    % use nexus proxy to build a nexon (assuming complete parameter set)
    nCORTEx=proxObj.nCORTEx;
    proxObj.nexon=startNexus(nCORTEx.params,[]);
    proxObj.proxon.nexon=proxObj.nexon;

end