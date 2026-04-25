function TF = nexOp_permuteApply(nexon, dfID, Y, P, fcn, match)
    
    % BASE
    if isempty(P.M)
        % splitapply and retrieve inputs
        TF_out = splitapply(@(Ysub) {nexOp_dealDF(nexon, dfID, Ysub, fcn)}, table2struct(Y), Y.trialNumber);
        % strip empty results
        isRes = cellfun(@(DF) ~isempty(DF), TF_out, "UniformOutput", true);
        TF = TF_out(isRes);
    else          
        M = P.M;
        varID = P.varID;
        TF = {}; % result accumulator
        for i = 1:size(M,1)
            match = M(i,:);
            rowSel = find(ismember(Y.(varID),match));
            Y_filt = Y(rowSel,:); % filter only selected matchings
            % order top-down by match order
            sortIdx = arrayfun(@(item) find(ismember(Y_filt.(varID),item)), match', "UniformOutput", false);
            sortIdx = cat(1, sortIdx{:});
            Y_filt = Y_filt(sortIdx,:);
            TF = [TF; nexOp_permuteApply(nexon, dfID, Y_filt, P.P, fcn, match)];
        end
    end

end