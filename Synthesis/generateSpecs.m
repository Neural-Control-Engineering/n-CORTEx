function T = generateSpecs(params, statParams, f, sampleSize, T_valid, F)
    % assign statistical boundaries 
    if isempty(statParams)
        statParams.CF.mean=0;
        statParams.CF.std = 10;
        statParams.PW.mean = 0.61374;
        statParams.PW.std = 0.26514;
        statParams.BW.mean = 2.1208;
        statParams.BW.std = 1.394/3;
        statParams.EXP.mean = 1.4027;
        statParams.EXP.std = 0.22807;
        statParams.OFF.mean = -8.7154;
        statParams.OFF.std = 0.32013;        
    end   
    paramFields = fieldnames(statParams);

    % initialize accumulators
    fooofParams = {};
    sampleType = [];
    dash = struct;
    dash.fh = uifigure("Position",[25,1260,1000, 600],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));    
    dash.panel1.ph1 = uipanel(dash.fh,"Position",[5,5,990,590],"BackgroundColor",[0,0,0]);
    dash.panel1.pltAx = axes(dash.panel1.ph1);    
    dash.panel1.pltAx = colorAx_green(dash.panel1.pltAx);
    for j = 1:sampleSize        
        numPeaks = round(rand() * 8)
        %% FOOOF PARAM SYNTHESIS
        % % Model distributions (normally distributed) and pull parameters        
        aperiodic_params = [];
        mu_OFF = statParams.OFF.mean;
        sigma_OFF = statParams.OFF.std;
        mu_EXP = statParams.EXP.mean;
        sigma_EXP = statParams.EXP.std;
        aperiodic_params = [aperiodic_params, normrnd(mu_OFF, sigma_OFF)];
        aperiodic_params = [aperiodic_params, normrnd(mu_EXP, sigma_EXP)];
        % generate random N number of peak sets        
        peak_params = [];                  
        for k = 1:numPeaks     
            % initialize peak param buffer            
            peakParamFields = paramFields(~strcmp(paramFields,"OFF") & ~strcmp(paramFields,"EXP"));
            peakRow = zeros(1,length(peakParamFields));
            for i = 1:length(peakParamFields)
                paramName = peakParamFields{i};            
                mu = statParams.(paramName).mean;
                sigma = statParams.(paramName).std;
                paramVal = normrnd(mu, sigma);            
                % assign to corresponding index                                
                switch  paramName
                    case "CF"
                        % update paramVal to align to frequency bins
                        mu = f(floor(size(f,2) / numPeaks) * k);                        
                        sigma = floor(size(f,2) / numPeaks) * 0.65;
                        paramVal = normrnd(mu, sigma);
                        peakRow(1) = paramVal;
                    case "PW"
                        peakRow(2) = paramVal;                        
                    case "BW"                    
                        peakRow(3) = paramVal;
                end
            end
            peak_params = [peak_params; peakRow];
        end
        % Compose fooof params (as specs struct)
        specs.aperiodic_params = aperiodic_params
        specs.peak_params = peak_params
        specs.peak_types = 'gaussian';
        %% PSD SYNTHESIS
        % Synthesize PSD from fooof params
        synthPSD = composeSpecs(f, specs);
        % inject noise
        if isempty(T_valid)
            synthPSD_noise = injectNoise(synthPSD);        
        elseif ~isempty(T_valid)
            synthPSD_noise = transplantNoise(f, synthPSD, T_valid, F);
        end
        if j == 1
            plot(dash.panel1.pltAx, f, synthPSD_noise,"Color",[1,0,0.5333])
            hold(dash.panel1.pltAx,"on");
            plot(dash.panel1.pltAx, f, synthPSD,"Color",[0.24,0.94,0.46])
        else
            plts = get(dash.panel1.pltAx,"Children");
            for i = 1:size(plts,1)                
                delete(plts(1));                
                plts = get(dash.panel1.pltAx,"Children");
            end            
            % add sig to plot
            line(f,synthPSD_noise,"Parent",dash.panel1.pltAx,"Color",[1,0,0.5333]);
            line(f,synthPSD,"Parent",dash.panel1.pltAx,"Color",[0.24,0.94,0.46]);
        end
        colorAx_green(dash.panel1.pltAx);
        drawnow
        
        specs.power_spectrum = synthPSD_noise;
        specs.freq = f;        
        % format samples
        fooofParams = [fooofParams; specs];
        sampleType = [sampleType; "Synthetic"];
        % pause(0.5)
    end
    T = table(fooofParams, sampleType, 'VariableNames', ["fooofparams", "sampleType"]);
end