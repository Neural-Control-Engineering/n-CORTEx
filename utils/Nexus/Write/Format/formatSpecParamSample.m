function df_specForm = formatSpecParamSample(df_spec, ax, dimension, freqVal)
    % assumed sequence AP, OFF, CF, PW, BW...
    switch dimension
        case "spectral"
            f = ax.f;
            % aperiodic base
            ap_params = [df_spec(1,1:2)];
            % periodic vector (arranged along f)
            periodicSignalVector = zeros(size(f,1),size(f,2)*2);
            CF_idxs = [1:(length(df_spec)-2)/3] .* 3;            
            CF_vals = df_spec(CF_idxs);
            CF_vals(CF_vals==0)=[];% drop zero padding
            sigVecIdxs = floor(CF_vals).*2;
            m=1; % spec indexing counter
            for i = sigVecIdxs
                periodicSignalVector(i)=df_spec(CF_idxs(m)+1);
                periodicSignalVector(i+1)=df_spec(CF_idxs(m)+2);
                m=m+1;
            end
            df_specForm = [ap_params, periodicSignalVector];
        case "spatial"
            chans = ax.chans;
            specSignalVector = zeros(size(chans,1),size(chans,2)*4);
            % get frequency specific params across channels
            CF_idxs = [1:(size(df_spec,2)-2)/3] .* 3;            
            CF_vals = floor(df_spec(:,CF_idxs));
            CF_vals(CF_vals==0) = nan; % avoid f=0 case
            freqMatchRows = (CF_vals==freqVal);              
            peakSlotNums = arrayfun(@(i) find(freqMatchRows(i,:)==1), chans', "UniformOutput",false);
            freqMatchRows = any(freqMatchRows,2);                        

            matchRowIdxs = find(freqMatchRows==1).*4+1;
            apRowIdxs = ([0:size(df_spec,1)-1]').*4+1;
            % assign aperiodic params
            m=1; % channel indexing counter
            for i = apRowIdxs
                specSignalVector(i) = df_spec(m,1);
                specSignalVector(i+1) = df_spec(m,2);
                m=m+1;
            end
            % assign periodic params (where appropriate)
            m=1;
            for i=matchRowIdxs     
                peakNum = peakSlotNums{(i-1)/4};
                specSignalVector(i+2) = df_spec(m,CF_idxs(peakNum)+1);
                specSignalVector(i+3) = df_spec(m,CF_idxs(peakNum)+2);
                m=m+1;
            end
        case "temporal"
            % get frequency specific params across time
            t = ax.t;
            specSignalVector = zeros(size(t,1),size(t,2)*4);
            % get frequency specific params across channels
            CF_idxs = [1:(size(df_spec,1)-2)/3] .* 3;            
            CF_vals = floor(df_spec(CF_idxs,:));
            CF_vals(CF_vals==0) = nan; % avoid f=0 case
            freqMatchCols = (CF_vals==freqVal);            
            peakSlotNums = arrayfun(@(i) find(freqMatchCols(:,i)==1), [1:size(freqMatchCols,2)], "UniformOutput",false);
            freqMatchCols = any(freqMatchCols,1);  

            matchColIdxs = find(freqMatchCols==1).*4+1;
            apColIdxs = ([0:size(df_spec,2)-1]').*4+1;
            % assign aperiodic params
            m=1; % channel indexing counter
            for i = apColIdxs
                specSignalVector(i) = df_spec(1,m);
                specSignalVector(i+1) = df_spec(2,m);
                m=m+1;
            end
            % assign periodic params (where appropriate)
            m=1;
            for i=matchColIdxs     
                peakNum = peakSlotNums{(i-1)/4};
                specSignalVector(i+2) = df_spec(CF_idxs(peakNum)+1,m);
                specSignalVector(i+3) = df_spec(CF_idxs(peakNum)+2,m);
                m=m+1;
            end
        case "batch"
            % aperiodic layer
            % [chanGrid, timeGrid] = ndgrid(1:size(df,1), 1:size(df,3));
            aperiodic_layer = df_spec(:,[1:2],:);
            aperiodic_layer = reshape(aperiodic_layer,[size(aperiodic_layer,1),size(aperiodic_layer,3)*2]);
            % periodic tensor
            [chanGrid, freqGrid, timeGrid] = ndgrid(1:size(df,1), (1:size(df,2)), (1:size(df,3)*2));
            tensorSlices = arrayfun(@(chan) formatSpecParamTensor(squeeze(df_spec(chan,:,:)), ax), chanGrid, "UniformOutput", false);
    end

    % exponential smoothing kernel?
end