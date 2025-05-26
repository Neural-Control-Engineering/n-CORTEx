function ctxControl_photon_loadObjective(nexObj)
    idx_loadObjective = 2;
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    photonCtrl_moveToPos(prxObj_photon, idx_loadObjective);                
end