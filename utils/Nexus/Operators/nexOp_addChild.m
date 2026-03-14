function nexOp_addChild(Parent, Child)    
    if ~isempty(Parent.Children)
        childFields = convertCharsToStrings(fieldnames(Parent.Children));
        % remove enumerator tag
        childFields = regexprep(childFields, '\d', '');
    else
        childFields = [];
    end
    

    if isprop(Child, "classID")
        objID = Child.classID;
    elseif isprop(Child,"modelID")
        objID = Child.modelID;
    end

    childFields_match = (strcmp(childFields, objID));
    numMatch = sum(childFields_match);
    subID = sprintf("%s%d",objID,numMatch+1);
    Parent.Children.(subID) = Child;
end