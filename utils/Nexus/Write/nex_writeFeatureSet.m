function nex_writeFeatureSet(nexObj, args)        

    % CFG HEADERS
    NUMFOLDS = args.numFolds; % default = 5
    labelIDs = args.labelIDs; % default = ["date","phase","subj"]

    labelIDs = ["date","phase","subj"];
    nexon = nexObj.nexon;
    numDtsRows = height(nexon.console.BASE.DTS);    

    numSamplesPerFold = floor(numDtsRows / NUMFOLDS);   
    m=1;
    tNum = 0;
    prevSessionLabel = grabDataFrame(nexon,"sessionLabel",1); % initial condition (might not be #1 in future)
    for i = 1:numDtsRows
        % grab dataframe (static dependent)

        % nexObj.DF.df = grabDataFrame(nexObj.nexon,nexObj.dfID,i);
        nexObj.DF = grabDF(nexObj, i);

        % compute and write feature given dataframe (recurse to children)
        sessionLabel = grabDataFrame(nexon,"sessionLabel",i);
        if ~strcmp(prevSessionLabel,sessionLabel)
            tNum=1; % reset trial counter
        else
            tNum = tNum+1;
        end
        prevSessionLabel = sessionLabel; % remember previous sessionLabel
        % trialNum = grabDataFrame(nexon,"trialNumber");
        disp(sessionLabel);
        tNum % COMMENT
        [labelVals, labelKeys] = nex_generateLabels(nexon,sessionLabel, labelIDs);        
        % iterable bookkeeping
        nexObj.UserData.labelIDs = ["trial",labelIDs];
        nexObj.UserData.labelKeys = labelKeys;
        nexObj.UserData.labelVals = [tNum; labelVals];
        nexObj.UserData.foldNum =  floor(m/numSamplesPerFold)+1;
        nexObj.UserData.sampleNum = m;
        writeArgs = extractMethodCfg('nex_writeFeature'); % default yes for now        
        try
            nex_writeFeature(nexObj, writeArgs);        
        catch e
            disp(getReport(e));                        
        end
        m=m+1;              
    end
end