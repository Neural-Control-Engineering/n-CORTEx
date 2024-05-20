function cdata = cMap2Regions(data, regMap)
    regMapFlip = flip(regMap,1);
    cdata = zeros(size(data,1),size(data,2),3);
    for i = 1:size(cdata,1)
        for j = 1:size(cdata,2)
            val = data(i,j);
            color = strcat('#',regMapFlip.color{i});
            color = hex2rgb(color);
            cdata(i,j,1) = color(1) * val;
            cdata(i,j,2) = color(2) * val;
            cdata(i,j,3) = color(3) * val;
        end
    end
end