function T_amp = amplifySpecsSet(params, f, T, F)
    shakeFactor = 0.15;
    fooofParams = {};
    sampleType = [];
    % generate dashboard
    dash = struct;
    % dash.fh = uifigure("Position",[25,1260,1000, 600],"Color",[0,0,0]);
    % load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));    
    % dash.panel1.ph1 = uipanel(dash.fh,"Position",[5,5,990,590],"BackgroundColor",[0,0,0]);
    % dash.panel1.pltAx = axes(dash.panel1.ph1);    
    % dash.panel1.pltAx = colorAx_green(dash.panel1.pltAx);
    for i = 1:height(T) % for each sample (dropout each peak, and jitter)
        valRow = T(i,:);
        valFooof = valRow.fooofparams{1};        
        psd_sample = valFooof.power_spectrum;
        sampleLabel  = valRow.sampleLabel;
        pmt_sample = grabPMT(sampleLabel, F);
        psd_comp = composeSpecs(f, valFooof);
        psd_noise = psd_sample - psd_comp;
        pmt_noise = pmt_sample - psd_comp;
        for j = 1:2
            switch j
                case 1
                    noise = psd_noise;
                case 2
                    noise = pmt_noise;
            end
            % perturb specs (x1)
            specs_perturb = {perturbSpecs(dash, f, noise, shakeFactor, valFooof)}; 
            % dropout specs (xNumSpecs)
            % specs_dropout = dropoutSpecs(dash, f, noise, valFooof);
        end
        % format samples
        % specsSet = [specs_perturb; specs_dropout];
        specsSet = [specs_perturb];
        sampleTypes = repmat("Synthetic",size(specsSet));
        fooofParams = [fooofParams; specsSet];
        sampleType = [sampleType; sampleTypes];
    end
    T_amp = table(fooofParams, sampleType, 'VariableNames', ["fooofparams", "sampleType"]);
end