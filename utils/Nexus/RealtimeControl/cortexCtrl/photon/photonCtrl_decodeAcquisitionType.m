function acquisitionType = photonCtrl_decodeAcquisitionType(typeCode)
    switch typeCode
        case 1
            acquisitionType = "TSeries";
        case 2
            acquisitionType = "";
        otherwise
            acquisitionType = "";
    end
end