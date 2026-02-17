function selection = nexSelect_categories(nexObj)
    nexon = nexObj.nexon;
    % prepare a dictionary for a bus selection    
    categoryList = nexOp_listCategories(nexon);
    % append with dims of nexObj
    categoryList = [categoryList; nexOp_listDfDims(nexObj.DF_postOp); "None"];
    nDims = size(categoryList,1);
    for i = 1:nDims
        selID = sprintf("C%d",i);
        categoryDict.(selID) = categoryList;
    end
    % categoryDict.C1 = categoryList;
    % categoryDict.C2 = categoryList;
    % categoryDict.C3 = categoryList;
    % keyFields = fieldnames(categoryDict);
    selection =  buildSelection(nexObj, categoryDict, length(categoryList));
end