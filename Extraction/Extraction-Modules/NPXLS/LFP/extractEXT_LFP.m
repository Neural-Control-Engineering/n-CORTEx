function LFP = extractEXT_LFP(params, session, LFP, Q)
    lfp = LFP.lfp;    
    %% POWER BANDS               
    % % Recover spectral power (macro)
    % [psdMacro, f_macro, t_macro] = cellfun(@(x) multiSpectrogram(x, LFP.fs{1}, 370, 185, 1), lfp, 'UniformOutput', false);      
    % [psdMacro_bands, b_macro] = cellfun(@(x, f) squeezeBands(params.bands, x, f, 1), psdMacro, f_macro, 'UniformOutput', false);      
    % psdMacro_bands = cellfun(@(x) 10*log10(abs(x)), psdMacro_bands, 'UniformOutput',false);
    % psdMacro_bands = cellfun(@(x) permute(x,[3,2,1]), psdMacro_bands, 'UniformOutput', false);    
    % LFP.psdMacro = psdMacro;
    % psdMacro_bands = cellfun(@(x) mat2cell(x, ones(1,size(x,1)), size(x,2), ones(1,size(x,3))), psdMacro, 'UniformOutput', false);
    % LFP.psdMacro = psdMacro;

    % spectral power (2 ms time bins, micro)
    
    %% UNCOMMENT FOR TIME-WISE PSDs
    % [psdMicro, f_micro, t_micro] = cellfun(@(x) multiSpectrogram(x, LFP.fs{1}, 80, 79, 1), lfp, 'UniformOutput', false);            
    % [psdMicro_bands, b_micro] = cellfun(@(x, f) squeezeBands(params.bands, x, f, 1), psdMicro, f_micro, 'UniformOutput', false);      
    % psdMicro_bands = cellfun(@(x) 10*log10(abs(x)), psdMicro_bands, 'UniformOutput',false);
    % psdMicro_bands = cellfun(@(x) permute(x,[3,2,1]), psdMicro_bands, 'UniformOutput', false);
    % LFP.psdMicro_bands = psdMicro_bands;
    % LFP.f_micro = f_micro;
    % LFP.t_micro = t_micro;
    % LFP.b_micro = b_micro;


    % psdMicro_bands = cellfun(@(x) mat2cell(x, ones(1,size(x,1)), size(x,2), ones(1,size(x,3))), psdMicro, 'UniformOutput', false);             
    % LFP.psdMicro = psdMicro;
    % bands = fieldnames(params.bands);
    % for i = 1:length(bands)
    %     band = bands{i};
    %     psdMicroTag = sprintf("psdMicro_%s",band);
    %     psdMacroTag = sprintf("psdMacro_%s",band);
    %     LFP.(psdMacroTag) = cellfun(@(x) x(:,:,i), psdMacro_bands, "UniformOutput", false);
    %     LFP.(psdMicroTag) = cellfun(@(x) x(:,:,i), psdMicro_bands, "UniformOutput", false);
    % end        
    
end