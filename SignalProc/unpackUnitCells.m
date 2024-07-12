function y = unpackUnitCells(x)
    if all(size(x)==1)
        y = x{1};
    else
        y= -1;
    end
end