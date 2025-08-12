function isMatch = compareArgs(args1, args2)
    try
        args1_cell = structfun(@(f) {f}, args1);
        args2_cell = structfun(@(f) {f}, args2);
        % args1_T = struct2table(args1_cell);
        % args2_T = struct2table(args2_cell);
        % args1_T = nex_struct2table(args1);
        % args2_T = nex_struct2table(args2);
        matchVals = cellfun(@(a, b) all(a==b), args1_cell, args2_cell, "UniformOutput", true);
        % matchIdxs = (args1_T == args2_T);
        % matchIdxs_mat = table2array(matchIdxs);
        % isMatch = all(matchIdxs_mat==1);
        isMatch = all(matchVals);
    catch e
        % disp(getReport(e));
        isMatch = false;
    end
end