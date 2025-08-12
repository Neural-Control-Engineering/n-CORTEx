function DF_form = formatSpec_timeFrequency(DF, specsMap)
    df_specs = DF.df;
    f_ax = DF.ax.f;
    fRange = [min((DF.ax.f)), max(DF.ax.f)];
    numPeaks=(size(df_specs,2)-2)/3;
    DF_form = DF;
    paramIDs = specsMap.param;
    % limitVals
    nChan = size(df_specs,1);
    nFreq = fRange(end) - fRange(1) + 1;
    nTime = size(df_specs,3);
    % idx_periodicParam=1;
    % for i = 1:length(paramIDs)
    %     ID_param = paramIDs(i);
    for i =1:length(paramIDs)
        ID_param = paramIDs(i);
        df_form.(ID_param)=(nan(size(df_specs,1),fRange(end)-fRange(1)+1,size(df_specs,3)));
    end

    % time-wise accumulators
    % OFF = [];
    % EXP = [];
    % CF = [];
    % PW = [];
    % BW = [];

    for t = 1:nTime
        specs_t = df_specs(:,:,t);  % [channels x 26]
    
        % Preallocate temporary results for this time
        tmp_OFF = num2cell(nan(nChan, 1));
        tmp_EXP = num2cell(nan(nChan, 1));
        tmp_CF  = num2cell(nan(nChan, 1));
        tmp_PW  = num2cell(nan(nChan, 1));
        tmp_BW  = num2cell(nan(nChan, 1));
    
        parfor ch = 1:nChan
            specs_row = specs_t(ch,:);
    
            % Get scalar values
            offVal = specs_row(specsMap.index(strcmp(specsMap.param,"OFF")));
            expVal = specs_row(specsMap.index(strcmp(specsMap.param,"EXP")));
            tmp_OFF{ch} = repelem(offVal,nFreq);
            tmp_EXP{ch} = repelem(expVal,nFreq);
    
            % Accumulate periodic components
            fRow_CF = nan(1,nFreq);
            fRow_PW = nan(1,nFreq);
            fRow_BW = nan(1,nFreq);
            for k = 1:numPeaks
                idx_CF = 3*k;
                idx_PW = 3*k+1;
                idx_BW = 3*k+2;
    
                cfVal = specs_row(idx_CF);
                pwVal = specs_row(idx_PW);
                bwVal = specs_row(idx_BW);
    
                % Map CF to frequency index
                [~, idx] = min(abs(f_ax - cfVal));
                if ~isnan(cfVal) && idx >= 1 && idx <= nFreq
                    fRow_CF(idx)=cfVal;
                    fRow_PW(idx)=pwVal;
                    fRow_BW(idx)=bwVal;
                end
            end
            tmp_CF{ch} = fRow_CF;
            tmp_PW{ch} = fRow_PW;
            tmp_BW{ch} = fRow_BW;
        end
        tmp_OFF = cat(1,tmp_OFF{:});
        tmp_EXP = cat(1,tmp_EXP{:});
        tmp_CF = cat(1,tmp_CF{:});
        tmp_PW = cat(1,tmp_PW{:});
        tmp_BW = cat(1,tmp_BW{:});
        % Assign to full output
        df_form.OFF(:,:,t) = tmp_OFF;
        df_form.EXP(:,:,t) = tmp_EXP;
        df_form.CF(:,:,t) = tmp_CF;
        df_form.PW(:,:,t) = tmp_PW;
        df_form.BW(:,:,t) = tmp_BW;    
        
    end   
    DF_form.df=df_form;
end

% figure;
% imgAx=imagesc();
% paramField="PW";
% for i=1:size(df_form.(paramField),3)
%     img = df_form.(paramField)(:,:,i);
%     imgAx.CData=img;
%     pause(0.1)
%     drawnow;
% end