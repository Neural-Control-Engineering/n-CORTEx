function specParams = allocateSpecs(band, specs)
    bRange = band.range;
    bName = band.name;
    tagCF = sprintf("%s_CF",bName);
    tagPW = sprintf("%s_PW",bName);
    tagBW = sprintf("%s_BW",bName);
    specParams.(tagCF) = {};
    specParams.(tagPW) = {};
    specParams.(tagBW) = {};
    for i = 1:size(specs,1)
        % disp(i);
        CF = specs(i,1);
        PW = specs(i,2);
        BW = specs(i,3);
        if CF > bRange(1) && CF < bRange(2)
            specParams.(tagCF) = [specParams.(tagCF); CF]; 
            specParams.(tagPW) = [specParams.(tagPW); PW];
            specParams.(tagBW) = [specParams.(tagBW); BW];
        else         
            specParams.(tagCF) = [specParams.(tagCF); NaN]; 
            specParams.(tagPW) = [specParams.(tagPW); NaN];
            specParams.(tagBW) = [specParams.(tagBW); NaN];
        end
    end

end