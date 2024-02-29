function time = timeAxis(data, fs, dim)
    seriesLen = size(data,dim);
    time = ([0:1:seriesLen-1])./fs;
end