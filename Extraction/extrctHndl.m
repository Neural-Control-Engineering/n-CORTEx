function hndl = extrctHndl(modality)
    hndl = sprintf("extract%s", modality);
    hndl = str2func(hndl);
end