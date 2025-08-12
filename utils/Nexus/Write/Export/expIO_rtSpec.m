function expIO_rtSpec(nexon, DF_tgt, DF_src, Y, fid_index, foldDir)
    % write data sample to batch; store label in the index
    % separate each channel
    n_chan = size(DF_tgt.df,1);
    n_time = size(DF_tgt.df,3);
    for i=1:n_chan
        for j=1:n_time
            % gather
            spec = DF_tgt.df(i,:,j);
            f_spec = DF_tgt.ax.f;
            psd_specs = 10*spec2psd(f_spec, spec,mode_AP,mode_PE);
            psd = DF_src.df(i,:,j);
            f_psd = DF_src.ax.f;
            fCond = (f_psd>=min(f_spec))&(f_psd<=max(f_spec));
            psd = psd(:,fCond,:);
            % figure; plot(psd_specs)            
            % hold on; plot(psd)            
            figure; loglog(psd_specs)            
            hold on; loglog(psd)            
            figure; loglog(psd)            
            
            f_psd = DF_src.ax.f;
            fCond = (f_psd>=f_spec)&(f_psd<=f_spec);
            f_psd = f_psd(fCond);
            psd = DF_src.df(i,:,j);
            psd = psd(fCond)
            psd_specs = 10*spec2psd(f_spec, spec);
            % psd_specs = spec2psd(f_spec, spec);
            % figure; plot(psd); hold on; plot(psd_specs)
            figure; plot(psd_specs);
            figure; plot(psd)
            % write sample
            % write to index
        end
    end
end

% figure;
% T = tiledlayout(2,10, 'TileSpacing', 'compact');
% xlabel(T, 'Frequency');
% ylabel(T, 'Power');
% 
% tileCount = 1;
% 
% for i = 1:20:380
%     for j = 9  % Only j=9 is used here, but this loop is redundant
%         if tileCount > T.GridSize(1) * T.GridSize(2)
%             break;  % Stop if we exceed number of tiles
%         end
% 
%         psd = DF_src.df(i,:,j);
%         f = DF_src.ax.f;
%         t = nexttile(T, tileCount);  % specify tile index explicitly
% 
%         loglog(t, f, psd);
%         ylim(t, [-200, -80]);
%         title(t, sprintf("i = %d, j = %d", i, j));
% 
%         tileCount = tileCount + 1;
%     end
% end
