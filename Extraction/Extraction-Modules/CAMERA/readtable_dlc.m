function [T, H] = readtable_dlc(path_dlcOutput)
    % --- Read first 3 header rows as raw text:
    fid = fopen(path_dlcOutput);
    hdr1 = strsplit(fgetl(fid), ',');   % scorer row
    hdr2 = strsplit(fgetl(fid), ',');   % body part row
    hdr3 = strsplit(fgetl(fid), ',');   % coords row
    fclose(fid);
    
    % --- Now read remaining data:
    T = readtable(path_dlcOutput, 'HeaderLines', 3);
    H.scorer = hdr1;
    H.bodyParts = hdr2;
    H.coords = hdr3;
end