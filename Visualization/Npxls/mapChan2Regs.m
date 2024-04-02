function [regMap, NT_color] = mapChan2Regs(meta, probe_areas)   
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
end