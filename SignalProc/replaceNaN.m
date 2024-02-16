function xRep = replaceNaN(x, val)    
    if isnan(x)
        xRep = val;
    else
        xRep = x;
    end
end