function R = nexOp_repElem(E, repHeight)
    switch class(E)
        case "cell"
            R = repelem(E,repHeight,1);
        case "string"
            R = repelem(E,repHeight,1);
        case "char"
            R = repelem(convertCharsToStrings(E),repHeight,1);
        case "double"
            R = repelem(E,repHeight,1);
        otherwise
            R=[];
    end
end