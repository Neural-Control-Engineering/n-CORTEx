function DTS_out = batch_npxls_cwt(DTS)
    % Check if 'PSD_cwt', 'f_cwt', and 't_cwt' columns exist, if not, add them to DTS
    if ~ismember('PSD_cwt', DTS.Properties.VariableNames)
        % Add empty columns for PSD_cwt, f_cwt, and t_cwt
        DTS.PSD_cwt = cell(height(DTS), 1);  % Empty cells for the spectral densities
        DTS.f_cwt = cell(height(DTS), 1);    % Frequencies for CWT
        DTS.t_cwt = cell(height(DTS), 1);    % Time values for CWT
    end
    
    selDTS = DTS;
    
    % Parallel loop to compute the CWT for each row
    PSD_cwt = {};
    f_cwt = {};
    t_cwt = {};    
    parfor i = 1:height(selDTS)
        cfg = struct;
        cfg.method="cwt";
        cfg.chanRange=1;
        % Extract LFP data for the current row
        dtRow = selDTS(i,:);
        lfp = dtRow.lfp{1};  % Assuming lfp is stored in a cell array              
        % with some configuration settings in 'cfg'    
        if ~isempty(lfp)
            [psd, freq, time] = computeSpectralDensity(cfg, lfp);  % Perform CWT and get PSD, freq, time
             % Store the computed results into the table
            PSD_cwt{i} = psd;
            f_cwt{i} = freq;
            t_cwt{i} = time;
        end             
    end
    selDTS.PSD_cwt = PSD_cwt';
    selDTS.f_cwt = f_cwt';
    selDTS.t_cwt = t_cwt';
    DTS_out = selDTS;
    % Return the updated DTS if necessary
    % e.g., assign it back to the caller if needed
    % DTS = selDTS;
end
