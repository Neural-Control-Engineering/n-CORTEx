function DTS1 = dtsIO_spliceMergeDTS(DTS1, DTS2)
    % find where trialNum and sessionLabel match and replace-assign DTS2 into DTS1
    trialNumMatch = (ismember(DTS1.trialNumber,DTS2.trialNumber));
    sessionLabelMatch = (ismember(DTS1.sessionLabel,DTS2.sessionLabel));
    matchRows = find(trialNumMatch & sessionLabelMatch);
    % matchCols = find(ismember(DTS1.Properties.VariableNames, DTS2.Properties.VariableNames));
    matchProps = convertCharsToStrings(DTS1.Properties.VariableNames(ismember(DTS1.Properties.VariableNames,DTS2.Properties.VariableNames)));
    % re-assign: 
    DTS1(find(matchRows), matchProps) = DTS2(:,matchProps);
    % DTSM = outerjoin(DTS1,DTS2,"Keys",["sessionLabel","trialNumber"],"MergeKeys",true);
    % DTSM = innerjoin(DTS1,DTS2,"Keys",["sessionLabel","trialNumber"]);
    % 


end