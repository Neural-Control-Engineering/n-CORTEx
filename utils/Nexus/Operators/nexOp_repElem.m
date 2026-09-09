function R = nexOp_repElem(E, repHeight)
    switch class(E)
        case "cell"
            R = repelem(E, repHeight, 1);
        case "string"
            R = repelem(E, repHeight, 1);
        case "char"
            R = repelem(convertCharsToStrings(E), repHeight, 1);
        otherwise
            if isnumeric(E) || islogical(E)
                R = repelem(E, repHeight, 1);
            else
                R = [];
            end
    end
end