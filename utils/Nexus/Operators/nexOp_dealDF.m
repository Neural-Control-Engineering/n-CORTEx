function DF_out = nexOp_dealDF(nexon, dfID, Y, fcn)   
    if isstruct(Y)
        Y = struct2table(Y);
    end
    idxSel = ismember([1:height(nexon.console.BASE.DTS)]', Y.index);
    % resort
    idxVals = find(idxSel==1);    
    idxSort = arrayfun(@(idxVal) find(idxVal==Y.index), idxVals);    
    dfID=strrep(dfID,"_df","");
    TF = dtsIO_readTF(nexon, dfID, idxSel);
    TF = TF(idxSort);
  
    args=extractMethodCfg(func2str(fcn));    
    % Combine dynamic inputs with fixed arguments
    argList = [TF; {args}];  % Stack inputs and fixed args
    try
        DF_out = feval(fcn, argList{:});
        varIDs=Y.Properties.VariableNames;
        L = varfun(@(V) nexOp_labelMatchup(V), Y);
        L.Properties.VariableNames=varIDs;
        L = table2struct(L);
        DF_out = mergeStructs(DF_out, L);
    catch e
        disp(getReport(e));
        DF_out = [];
    end
  
end