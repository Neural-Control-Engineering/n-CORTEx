function [T, discT] = labelTrainingSet_specParams(params, DTS)
    % recover labeling progress - this is a csv in the project directory
    % labelSetPath = fullfile(params.paths.Data.FTR.cloud, "TRAIN","RTSpec","labels.mat");    
    % discSetPath = fullfile(params.paths.Data.FTR.cloud,"TRAIN","RTSpec","disc.mat");
    labelSetPath = fullfile(params.paths.Data.FTR.local, "TRAIN","RTSpec","labels.mat");    
    discSetPath = fullfile(params.paths.Data.FTR.local,"TRAIN","RTSpec","disc.mat");

    if ~isfile(labelSetPath)
        % make a new label csv
        T=[];
        T.fooofparams=[];
        T.date={};
        T.pawSide={};
        T.phase={};
        T.trialNum=[];
        T.channelNum=[];  
        T.sampleLabel = [];     
        % T = struct2table(T);
    else
        % load existing label csv
        load(labelSetPath,"T");   
        T = table2struct(T);       
    end

    if ~isfile(discSetPath)
        discT = [];
        discT.sampleLabel = [];
    else
        load(discSetPath,"discT");
        discT = table2struct(discT);         
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
     % dash.fh = uifigure("Position",[25,1260,800, 600],"Color",[0,0,0]);
     dash.fh = uifigure("Position",[25,1260,1000, 600],"Color",[0,0,0]);
     load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
     % colormap(dash.fh,CT);
     dash.panel1.ph1 = uipanel(dash.fh,"Position",[5,5,570,590],"BackgroundColor",[0,0,0]);     
     dash.panel1.pltAx = axes(dash.panel1.ph1);         

     % Store data
     dash.fooofParams = DTS.fooofparams;     
     dash.PSDfits = DTS.powspctrm;
     dash.T = T;
     dash.tT = struct2table(T);
     dash.discT = discT;
     dash.tdiscT = struct2table(discT);
     dash.bands = frqBins;
     dash.labelSetPath = labelSetPath;
     dash.discSetPath = discSetPath;     

     dash.panel2.ph1 = uipanel(dash.fh,"Position",[578,5,200,590],"BackgroundColor",[0,0,0]);
     dash.panel2.errorLabel = uilabel(dash.panel2.ph1,"Position",[10,560,150,20],"Text",sprintf("ERROR: --"),"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"FontSize",16);
     dash.panel2.b1 = uibutton(dash.panel2.ph1,"Position",[45,420,100,100],"BackgroundColor",[0.24,0.94,0.46],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 1),"Text","+");     
     dash.panel2.b2 = uibutton(dash.panel2.ph1,"Position",[45,270,100,100],"BackgroundColor",[1,0,0.2667],"FontColor",[[1,0,0.2667]],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 0),"Text","-");
     dash.panel2.b3 = uibutton(dash.panel2.ph1,"Position",[45,120,100,100],"BackgroundColor",[0, 0.4471, 0.7412],"FontColor",[0, 0.4471, 0.7412],"ButtonPushedFcn",@(~,~)saveSpecsButtonPressed(dash, 2),"Text","-");
     % specs UI panel
     dash.panel3.ph1 = uipanel(dash.fh,"Position",[782,5,200,590],"BackgroundColor",[0,0,0]);
     dash.fh.UserData = dash;
    % specs Interfacing buttons
     dash.panel2.b4 = uibutton(dash.panel2.ph1,"Position",[45,55,40,30],"BackgroundColor",[0, 0, 0],"FontSize",14,"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)uiAddSpec(dash),"Text","+");     
     dash.panel2.b5 = uibutton(dash.panel2.ph1,"Position",[45,20,40,30],"BackgroundColor",[0, 0, 0],"FontSize",14,"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)uiResetSpecs(dash),"Text","Reset");
     dash.panel2.b6 = uibutton(dash.panel2.ph1,"Position",[90,20,55,65],"BackgroundColor",[0, 0, 0],"FontSize",14,"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)uiRecoverPrevSpecs(dash),"Text","Set-prev");
     dash.fh.UserData = dash;
     
     

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
        PMT = DTS.powspctrm_pmt{i};
        freq = DTS.freq(i,:); % assuming all f axes are identical

        dash.fh.UserData.pawSide = pawSide;
        dash.fh.UserData.trialNum = trialNum;
        dash.fh.UserData.date = date;
        dash.fh.UserData.phase = phase;
        for j = 1:7:size(fooofParams,1)
            if j ==size(fooofParams)
                T = dash.fh.UserData.T;
                discT = dash.fh.UserData.discT;
                return
            end
            j = j+5;
            chanNum = j;            
            % matches = (T.date == date) & (T.trialNum == trialNum) & (T.channelNum == chanNum);
            % if ~all(matches==1) || isempty(matches)
            try
                specs = fooofParams(j);  % is idx doesnt match continue to next iteration
            catch
                continue
            end
            specs.freq = freq;
            psdFit = PSDfits(j,:);
            % waitfor(dash.fh,"UserData","ButtonPressed")                
            dash.fh.UserData.i = i;
            dash.fh.UserData.j = j;              
            dash.fh.UserData.specs = specs;
            dash.fh.UserData.specs_backup = specs;
            dash.fh.UserData.psdFit = psdFit;                
            dash.fh.UserData.channelNum = chanNum;   
            dash.fh.UserData.sampleType="Verified";
            dash.fh.UserData.smpLbl = sprintf("%s_trialNum--%d_chanNum--%d", sessionLabel, trialNum, chanNum);
            % dash.fh.UserData.binnedParams = binFooofParams(frqBins, fooofParams);
            % test only unvisited samples
            fprintf("channel: %d",chanNum);
            fprintf("trial: %d",(trialNum));
            fprintf("\n")            
            % starting case (if table version of T is empty)
            if isempty((dash.fh.UserData.tT.sampleLabel))
                dash.panel2.errorLabel.Text = sprintf("ERROR: %s",num2str(specs.error)); 
                plot(dash.panel1.pltAx, freq, specs.power_spectrum,"Color",[0.24,0.94,0.46]);
                hold(dash.panel1.pltAx,"on")
                % plot(dash.panel1.pltAx, log10(psdFit),"Color",[1,1,1]);
                pmtCond = [1:size(specs.power_spectrum,2)];
                plot(dash.panel1.pltAx, freq, log10(PMT(pmtCond,chanNum)),"Color",[0.651,0.651,0.651]);
                dash.panel1.pltAx = colorAx_green(dash.panel1.pltAx);
                % DRAW SPECS UI                
                % drawSpecsUI(dash, specs, freq, 0);
                plot(dash.panel1.pltAx, freq, log10(specs.fooofed_spectrum),"Color",[1,0,0.5333])
                % Wait for user entry
                uiwait(dash.fh);                             
            elseif ~ismember(dash.fh.UserData.smpLbl, dash.fh.UserData.tT.sampleLabel) && ~ismember(dash.fh.UserData.smpLbl, dash.fh.UserData.tdiscT.sampleLabel)
                % plot specs fitting for QC
                dash.panel2.errorLabel.Text = sprintf("ERROR: %s",num2str(specs.error)); 
                plot(dash.panel1.pltAx, freq, specs.power_spectrum,"Color",[0.24,0.94,0.46]);
                hold(dash.panel1.pltAx,"on")
                % plot(dash.panel1.pltAx, log10(psdFit),"Color",[1,1,1]);
                pmtCond = [1:size(specs.power_spectrum,2)];
                plot(dash.panel1.pltAx, freq, log10(PMT(pmtCond,chanNum)),"Color",[0.651,0.651,0.651]);
                dash.panel1.pltAx = colorAx_green(dash.panel1.pltAx);
                % DRAW SPECS UI                
                % drawSpecsUI(dash, specs, freq, 0);
                plot(dash.panel1.pltAx, freq, log10(specs.fooofed_spectrum),"Color",[1,0,0.5333])
                % Wait for user entry
                uiwait(dash.fh);                                             
            end
            % end
        end
        
    end

    T = dash,fh.UserData.T;

    % Continue loop: Show fit overlay, original spectrum, and report error
    % metrics - Plot in interactive UI

    % Append X = PSD, Y1-YN = date, pawSide, phase, trialNum, channelNum, specParams

    % *** closing fcn to save progress when complete; saving fcn to
    % interactively save; good/bad fcn button to evaluate


end
