function channelGram = nexPlot_npxls_channelGram(nexon, shank, channelGram)
    switch channelGram.isAnimated
        case 0
            chgFigure.fh2 = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
            chgFigure.ph = uipanel(chgFigure.fh2,"Position",[5,5,490,490],"BackgroundColor",[0,0,0]);
            chgFigure.Ax2 = axes(chgFigure.ph);
            [PSD_fullWindow, f_psdFull] = pmtm(lfp(:,1750:3750)', 10, 2048, 500 ,'Tapers','sine');     
            fCond = (f_psdFull <= 50);
            imagesc(chgFigure.Ax2,"YData",[1:385],"XData",f_psdFull(fCond==1),"CData",log10(PSD_fullWindow(fCond==1,:)'));
            chgFigure.Ax2.CLim=[-11.2,-8.5];
            colorAx_green(chgFigure.Ax2);
        case 1
            chgFigure.fh = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
            chgFigure.panel1.ph=uipanel(chgFigure.fh,"Position",[5,5,490,470],"BackgroundColor",[0,0,0]);
            chgFigure.panel1.tiles.t = tiledlayout(chgFigure.panel1.ph,1,1);
            % Buttons
            chgFigure.playButton = uibutton(chgFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)nexPlayPause(channelGram),"Position",[5,477,22,22]); % next
            % channel gram
            chgFigure.panel1.tiles.Axes.channelGram = nexttile(chgFigure.panel1.tiles.t);           
            chgFigure.panel1.tiles.Axes.channelGram= surf(chgFigure.panel1.tiles.Axes.channelGram,"CData",[]);
            % view(chgFigure.panel1.tiles.Axes.channelGram.Parent, [30 30]);  % Adjust the 3D view angle
            chgFigure.panel1.tiles.Axes.channelGram.EdgeColor="none";                
            % RTSpec            
            % channelGram.
            % [PSD_fullWindow, f_psdFull] = pmtm(lfp(:,1750:3750)', 10, 2048, 500 ,'Tapers','sine');     
            % fCond = (f_psdFull <= 50);
            frameNum = channelGram.frameNum;
            chanRange = channelGram.psdCfg.chanRange;
            % lfp_frame = channelGram.dataFrame(chanRange,frameNum);
            lfp_frame = channelGram.dataFrame(chanRange,frameNum:frameNum+channelGram.psdCfg.windowLen)';
            switch channelGram.psdCfg.method
                case "fft"
                    SFT = extractRT_FFT(channelGram.psdCfg, lfp_frame);
                case "pmtm"
                    SF = extractRT_PMTM(channelGram.psdCfg, lfp_frame);
                    sChans = [SF{1,1}{:}]';                    
                    f = SF{1,2}{1};
                case "stft"
                    SFT = extractRT_STFT(channelGram.psdCfg, lfp_frame);
                    f = SFT{1,2}{1};
                    t = SFT{1,3}{1};
                    S = SFT{1,1};
                    sAvg = cellfun(@(x) mean(10*log10(abs(x)),2),S,"UniformOutput",false);
                    sChans = [sAvg{:}]';
                    % stftIdx = streamCfg.chanViewSel;
            end
            fCond = f(f>channelGram.psdCfg.fRange(1) & f<channelGram.psdCfg.fRange(2));
            f_psd = resampleDataFrame(f(fCond),195);
            sChans = sChans(:,fCond);            
            % plot spectral power
            chgFigure.panel1.tiles.Axes.channelGram.YData = gather([1:size(sChans,1)]);
            chgFigure.panel1.tiles.Axes.channelGram.XData = gather(f(fCond));
            chgFigure.panel1.tiles.Axes.channelGram.ZData = gather(sChans);    
            chgFigure.panel1.tiles.Axes.channelGram.CData = gather(sChans);    
            % set ax Lims
            Zmax = max(max(sChans));
            Zmin = min(min(sChans));
            chgFigure.panel1.tiles.Axes.channelGram.Parent.ZLim = [Zmin*1.05,Zmax*0.9];
            chgFigure.panel1.tiles.Axes.channelGram.Parent.CLim=[-118,-95]./10;
            %% plot Fooof reconstruction            
            % chgFigure.panel1.tiles.Axes.fooof = nexttile(chgFigure.panel1.tiles.t);                                   
            % fooofPredictions = extractRT_fooof(channelGram.rtSpec,sChans);
            % chgFigure.panel1.tiles.Axes.fooof = plotFooofContours(chgFigure.panel1.tiles.Axes.fooof, f_psd, fooofPredictions);            
            % figure color mapping            
            load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
            colormap(chgFigure.fh,CT);
            % channelGram plot
            chgFigure.panel1.tiles.Axes.channelGram.Parent.Color=[0,0,0];      
            chgFigure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.Color=[0.24,0.94,0.46];             
            chgFigure.panel1.tiles.Axes.channelGram.Parent.GridColor=[0.24,0.94,0.46];             
            chgFigure.panel1.tiles.Axes.channelGram.Parent.XColor=[0.24,0.94,0.46];
            chgFigure.panel1.tiles.Axes.channelGram.Parent.YColor=[0.24,0.94,0.46];
            chgFigure.panel1.tiles.Axes.channelGram.Parent.ZColor=[0.24,0.94,0.46];
            % fooof plot
            % chgFigure.panel1.tiles.Axes.fooof.Color=[0,0,0];            
            % chgFigure.panel1.tiles.Axes.fooof.GridColor=[0.24,0.94,0.46];             
            % chgFigure.panel1.tiles.Axes.fooof.XColor=[0.24,0.94,0.46];
            % chgFigure.panel1.tiles.Axes.fooof.YColor=[0.24,0.94,0.46];
            % chgFigure.panel1.tiles.Axes.fooof.ZColor=[0.24,0.94,0.46];
            % chgFigure.panel1.tiles.Axes.fooof.ZLim = [Zmin*1.05,Zmax*0.9];
            % chgFigure.panel1.tiles.Axes.fooof.CLim=[-118,-95]./10;
            channelGram.chgFigure=chgFigure; % assign back to channelGram
    end
end