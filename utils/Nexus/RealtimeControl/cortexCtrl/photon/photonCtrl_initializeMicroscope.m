function photonCtrl_initializeMicroscope(nexObj)
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    % locate physical home position of microscope
    photonCtrl_locatePhysicalHome(prxObj_photon);
    
end