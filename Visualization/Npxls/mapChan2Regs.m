function regMap = mapChan2Regs(probe_areas)   
    [metaFile, metaFldr] = uigetfile(".bin.meta");
    % metaPath = fullfile(metaPath, metaFile);
    try
        meta = ReadMeta(metaFile,metaFldr);
    catch
        % When the true path exceeds Windows MAX_PATH (260), the file dialog returns
        % 8.3 short names (e.g. DATE--~2.MET). ReadMeta then rebuilds "name + .meta",
        % but 8.3 truncates the extension to 3 chars, so the rebuilt name doesn't
        % exist. The short path itself IS openable, so copy the exact selected file
        % (whatever its 8.3 name) to a clean temp path and read it there.
        tmpDir = tempname; mkdir(tmpDir);
        clean  = onCleanup(@() rmdir(tmpDir, 's'));         %#ok<NASGU>
        copyfile(fullfile(char(metaFldr), char(metaFile)), fullfile(tmpDir, 'staged.meta'));
        meta = ReadMeta('staged.meta', tmpDir);
    end
    geomap = meta.snsGeomMap;
    geom = split(geomap,')');
    geom = cellfun(@(x) strrep(x,'(',''), geom, "UniformOutput",false);
    geom = convertCharsToStrings(geom);
    geom = arrayfun(@(x) split(x,':',2),geom,"UniformOutput",false);
    geom = geom(2:end-1);
    
    % geom = cellfun(@(x) split(x,':'), geom, "UniformOutput", false);
    regMap = struct;
    regMap.shank = {};
    regMap.channel = {};
    regMap.X = {};
    regMap.Y = {};
    regMap.region = {};
    regMap.color = {};

    probeTrj = probe_areas{1,1};
    probeRegs = probeTrj(:,{'probe_tip_distance','safe_name','acronym','color_hex_triplet'});    
    % probeRegs = probeTrj(:,{'probe_depth','safe_name','acronym','color_hex_triplet'});    

    for i = 1:length(geom)
        geo = geom{i};
        shank = str2double(geo(1));
        x = str2double(geo(2));
        y = str2double(geo(3)); 
        y_tipDist = y + 175;
        region = findRegion(probeRegs, y_tipDist);
        regMap.region = [regMap.region; region.acronym];
        regMap.color = [regMap.color; region.color_hex_triplet];
        regMap.shank = [regMap.shank; shank];
        regMap.channel = [regMap.channel; i];
        regMap.X = [regMap.X; x];
        regMap.Y = [regMap.Y; y];        
    end
    regMap = struct2table(regMap);
    regMap = sortrows(regMap,'Y');
    regMap = flip(regMap,1);
end