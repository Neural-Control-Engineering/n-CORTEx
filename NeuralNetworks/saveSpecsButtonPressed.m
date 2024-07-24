function saveSpecsButtonPressed(dash,buttonStat)
    switch buttonStat
        case 1 % KEEP
            % append row of data
            dash.fh.UserData.T.channelNum = [dash.fh.UserData.T.channelNum; dash.fh.UserData.channelNum];
            dash.fh.UserData.T.trialNum = [dash.fh.UserData.T.trialNum; dash.fh.UserData.trialNum];
            dash.fh.UserData.T.date = [dash.fh.UserData.T.date; dash.fh.UserData.date];
            dash.fh.UserData.T.pawSide = [dash.fh.UserData.T.pawSide; dash.fh.UserData.pawSide];
            dash.fh.UserData.T.phase = [dash.fh.UserData.T.phase; dash.fh.UserData.phase];
            dash.fh.UserData.T.fooofparams = [dash.fh.UserData.T.fooofparams; dash.fh.UserData.specs];
        case 0 % DISCARD
        case 2 % save progress
            save(dash.fh.UserData.labelSetPath,dash.fh.UserData.T);
    end
    cla(dash.panel1.pltAx)         
    uiresume(dash.fh);
end