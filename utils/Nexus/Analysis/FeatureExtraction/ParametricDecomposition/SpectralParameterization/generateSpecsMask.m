function SM = generateSpecsMask(DF)
    % write a 'binary'-esqe mask of spectral parameters for visualization
    % score 0 for no value, 1 for bandwidth, <PW> for power @ <CF>
    % limitVals
    nChan = size(DF.ax.chans,2);    
    nFreq = size(DF.ax.f,2);
    nTime = size(DF.ax.t,2);
    f = DF.ax.f;
    
    SM = nan(nChan,nFreq,nTime);
    parfor t = 1:nTime
        SM_t = cell(nChan,1);
        for j = 1:nChan
            % disp(j)
            specsRow_CF = DF.df.CF(j,:,t);
            specsRow_PW = DF.df.PW(j,:,t);
            specsRow_BW = DF.df.BW(j,:,t);
            % idxs_peaks = find(specsRow_CF~=0);
            idxs_peaks = find(~isnan(specsRow_CF));
            cf_peaks = specsRow_CF(idxs_peaks);
            pw_peaks = specsRow_PW(idxs_peaks);
            bw_peaks = specsRow_BW(idxs_peaks);
            maskRow = nan(1,nFreq);            
            for i = 1:length(idxs_peaks)
                % disp(i)r
                idx = idxs_peaks(i);
                cf = cf_peaks(i);
                pw = pw_peaks(i);
                bw = round(bw_peaks(i));
                bw_start = cf-bw;                
                bw_end = cf+bw;
                [~, idx_f_start] = min(abs((f-bw_start)));
                [~, idx_f_end] = min(abs((f-bw_end)));
                % if idx+bw > size(maskRow,2) && idx-bw <= 0                
                %     maskRow(1:end)=1;
                % elseif idx+bw > size(maskRow,2)
                %     maskRow(idx-bw:end)=1;
                % elseif idx-bw <= 0
                %     maskRow(1:idx+bw)=1;
                % else
                %     maskRow(idx-bw:idx+bw)=1;
                % end
                maskRow(idx_f_start:idx_f_end)=1;
                maskRow(idx) = pw;
                % maskRow()
            end
            SM_t{j} = maskRow;

        end
        SM_t = cat(1,SM_t{:});
        SM(:,:,t) = SM_t;
    end

    % figure; imgAx=imagesc();
    % for i = 1:nTime
    %     img = SM(:,:,i);
    %     imgAx.CData=img;
    %     pause(0.2)
    %     title(i);
    %     drawnow;
    % end
    % % 
    
end

