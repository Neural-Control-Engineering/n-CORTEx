
function isMatch = compareArgs(args1, args2)
    try
        args1_T = struct2table(args1);
        args2_T = struct2table(args2);
        matchIdxs = (args1_T == args2_T);
        matchIdxs_mat = table2array(matchIdxs);
        isMatch = all(matchIdxs_mat==1);
    catch e
        % disp(getReport(e));
        isMatch = false;
    end
end