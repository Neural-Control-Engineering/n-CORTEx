function labelTrainingSet_specParams(params, DTS)
    % recover labeling progress - this is a csv in the project directory
    labelSetPath = fullfile(params.paths.Data.FTR.cloud, "TRAIN","RTSpec","labels.mat");    

    if ~isfile(labelSetPath)
        % make a new label csv
        T=[];
        T.fooofparams=[];
        T.date={};
        T.pawSide={};
        T.phase={};
        T.trialNum=[];
        T.channelNum=[];  
        
        % T = struct2table(T);
    else
        % load existing label csv
    end

    % frequency binning
    frqBins = struct;
    step = 2;
    for i = 1:step:50
        frqBin = sprintf("f%d",i);
        frqBins.(frqBin) = [i, i+step-1];
    end
    
    % DRAW DASH
     dash = struct;
     dash.fh = uifigure("Position",[25,1260,800, 600],"Color",[0,0,0]);
     load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
     % colormap(dash.fh,CT);
     dash.panel1.ph1 = uipanel(dash.fh,"Position",[5,5,570,590],"BackgroundColor",[0,0,0]);     
     dash.panel1.pltAx = axes(dash.panel1.ph1);         

     % Store data
     dash.fooofParams = DTS.fooofparams;     
     dash.PSDfits = DTS.powspctrm;
     dash.T = T;
     dash.bands = frqBins;
     dash.labelSetPath = labelSetPath;

     dash.fh.UserData = dash;

     dash.panel2.ph1 = uipanel(dash.fh,"Position",[578,5,200,590],"BackgroundColor",[0,0,0]);
     dash.panel2.errorLabel = uilabel(dash.panel2.ph1,"Position",[10,560,150,20],"Text",sprintf("ERROR: %s",num2str(specs.error)),"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"FontSize",16);
     dash.panel2.b1 = uibutton(dash.panel2.ph1,"Position",[10,400,100,100],"BackgroundColor",[0.24,0.94,0.46],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 1),"Text","+");     
     dash.panel2.b2 = uibutton(dash.panel2.ph1,"Position",[10,250,100,100],"BackgroundColor",[1,0,0.2667],"FontColor",[[1,0,0.2667]],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 0),"Text","-");
     dash.panel2.b3 = uibutton(dash.panel2.ph1,"Position",[10,100,100,100],"BackgroundColor",[0, 0.4471, 0.7412],"FontColor",[0, 0.4471, 0.7412],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 2),"Text","-");

    % Loop through unvisited trials
    for i=1:height(DTS)
        sessionLabel = DTS.sessionLabel{i};
        % date
        date = convertCharsToStrings(parseSessionLabel(sessionLabel,"date"));        
        % pawSide
        phase = convertCharsToStrings(parseSessionLabel(sessionLabel,"phase"));
        pawSide = split(phase,"-");
        pawSide = pawSide(1);
        trialNum = DTS.trialNum(i);
        fooofParams = DTS.fooofparams{i};
        PSDfits = DTS.powspctrm{i};

        dash.fh.UserData.pawSide = pawSide;
        dash.fh.UserData.trialNum = trialNum;
        dash.fh.UserData.date = date;
        dash.fh.UserData.phase = phase;
        for j = 1:size(fooofParams,1)
            chanNum = j;            
            matches = (T.date == date) & (T.trialNum == trialNum) & (T.channelNum == chanNum);
            if ~all(matches==1) || isempty(matches)
                specs = fooofParams(j);
                psdFit = PSDfits(j,:);
                % waitfor(dash.fh,"UserData","ButtonPressed")                
                dash.fh.UserData.i = i;
                dash.fh.UserData.j = j;              
                dash.fh.UserData.specs = specs;
                dash.fh.UserData.psdFit = psdFit;                
                dash.fh.UserData.channelNum = chanNum;                     
                % dash.fh.UserData.binnedParams = binFooofParams(frqBins, fooofParams);
                % plot specs fitting for QC
                plot(dash.panel1.pltAx, specs.power_spectrum,"Color",[0.24,0.94,0.46]);
                hold(dash.panel1.pltAx,"on")
                plot(dash.panel1.pltAx, log10(psdFit),"Color",[1,1,1]);
                dash.panel1.pltAx = colorAx_green(dash.panel1.pltAx);
                % Wait for user entry
                uiwait(dash.fh);                                             
            end
        end
        
    end

    % Continue loop: Show fit overlay, original spectrum, and report error
    % metrics - Plot in interactive UI

    % Append X = PSD, Y1-YN = date, pawSide, phase, trialNum, channelNum, specParams

    % *** closing fcn to save progress when complete; saving fcn to
    % interactively save; good/bad fcn button to evaluate


end
