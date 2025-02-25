function saveSpecsButtonPressed(dash,buttonStat)
    switch buttonStat
        case 1 % KEEP
            % append row of data
            % disp(dash.fh.UserData.channelNum);
            % disp(dash.fh.UserData.trialNum);
            row = struct;
            % dash.fh.UserData.T.sampleLabel = [dash.fh.UserData.T.sampleLabel; dash.fh.UserData.smpLbl];
            % dash.fh.UserData.T.channelNum = [dash.fh.UserData.T.channelNum; dash.fh.UserData.channelNum];
            % dash.fh.UserData.T.trialNum = [dash.fh.UserData.T.trialNum; dash.fh.UserData.trialNum];
            % dash.fh.UserData.T.date = [dash.fh.UserData.T.date; dash.fh.UserData.date];
            % dash.fh.UserData.T.pawSide = [dash.fh.UserData.T.pawSide; dash.fh.UserData.pawSide];
            % dash.fh.UserData.T.phase = [dash.fh.UserData.T.phase; dash.fh.UserData.phase];
            % dash.fh.UserData.T.fooofparams = [dash.fh.UserData.T.fooofparams; dash.fh.UserData.specs];

            row.sampleLabel = [dash.fh.UserData.smpLbl];
            row.channelNum = [dash.fh.UserData.channelNum];
            row.trialNum = [dash.fh.UserData.trialNum];
            row.date = [dash.fh.UserData.date];
            row.pawSide = [dash.fh.UserData.pawSide];
            row.phase = [dash.fh.UserData.phase];
            row.fooofparams = [dash.fh.UserData.specs];
            row.sampleType = [dash.fh.UserData.sampleType];
            dash.fh.UserData.prevSpecs = dash.fh.UserData.specs;

            dash.fh.UserData.T = [dash.fh.UserData.T; row];
        case 0 % DISCARD
            rowDisc = struct;
            rowDisc.sampleLabel = [dash.fh.UserData.smpLbl];
            dash.fh.UserData.discT = [dash.fh.UserData.discT; rowDisc];
        case 2 % save progress
            row = struct;            
            row.sampleLabel = [dash.fh.UserData.smpLbl];
            row.channelNum = [dash.fh.UserData.channelNum];
            row.trialNum = [dash.fh.UserData.trialNum];
            row.date = [dash.fh.UserData.date];
            row.pawSide = [dash.fh.UserData.pawSide];
            row.phase = [dash.fh.UserData.phase];
            row.fooofparams = [dash.fh.UserData.specs];
            row.sampleType = [dash.fh.UserData.sampleType];
            dash.fh.UserData.prevSpecs = dash.fh.UserData.specs;

            dash.fh.UserData.T = [dash.fh.UserData.T; row];
            T = struct2table(dash.fh.UserData.T);
            discT = struct2table(dash.fh.UserData.discT);
            save(dash.fh.UserData.labelSetPath,"T");
            save(dash.fh.UserData.discSetPath,"discT");            
    end    
    cla(dash.panel1.pltAx)         
    uiresume(dash.fh);
end