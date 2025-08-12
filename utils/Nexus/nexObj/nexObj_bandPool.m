classdef nexObj_bandPool < handle
    properties
        dataFrame % This will hold any type of data, such as a struct  
        evDataFrame
        entryPanel
        dfID % DTS df identifier (trial-wise)
        eventID
        b % band axis
        evs % event list
        t % time axis   
        bpFigure % figure handle
        UserData
    end
    
    methods
        % Constructor
        function obj = nexObj_bandPool(nexon, spectroGram, b, t, evs, dataFrame, eventID)
            obj.dataFrame=dataFrame;            
            obj.evDataFrame = grabDataFrame(nexon, eventID);
            obj.eventID = eventID;
            obj.b = b; % band list (string)
            obj.evs = evs; % event list (string)
            obj.t = t; % time axis
            obj.UserData = struct;            
            obj.bpFigure = nexPlot_bandPool(nexon, spectroGram, obj);            
        end

        function updateBandPool(obj, nexon, spectroGram)
            spgID = extractMod(spectroGram.dfID);
            spg = grabSpectrogram(nexon, spgID);            
            obj.t = spg.t;
            % update tileset
            tileSetFields = fieldnames(obj.bpFigure.panel1.tiles.Axes);               
            b = obj.b;
            [poolDf, b] = poolBands(nexon.console.BASE.params.bands, spectroGram.f, spg.dataFrame); % recover neural bands again    
            obj.dataFrame = poolDf;
            freqResponse = spectroGram.freqResponse;
            for i = 1:length(tileSetFields) % visit each existing trace name, if band, use poolDf, if event, use grabDf
                tileID = tileSetFields{i};
                try                    
                    dfTrace = poolDf(:,find(strcmp(tileID,b)==1),:);          
                    switch freqResponse
                        case "mag"
                            dfTrace = 10*log10(abs(dfTrace));
                        case "phase"
                            dfTrace = angle((dfTrace));
                    end
                    t = spg.t;
                catch
                    dfTrace = grabDataFrame(nexon, tileID);
                    t = spg.t; % FIX LATER with a grabDf
                end
                % traceColor = sprintf("#%s",regMap(regMap.channel==ptrIdx,:).color{1});
                updatePlotAx(obj.bpFigure.panel1.tiles.Axes.(tileID), t, squeeze(dfTrace),"#0da1ce");
                % updatePlotAx(obj.bpFigure.panel1.tiles.Axes.(tileID), t, squeeze(dfTrace),nexon.settings.Colors.cyberGreen);
                % timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);
                colorAx_green(obj.bpFigure.panel1.tiles.Axes.(tileID));
            end
            drawnow
        end

        function horizon(obj, nexon, spectroGram) % gather and plot data from other trials in the session
            spgID = extractMod(spectroGram.dfID);
            session = grabSession(nexon); % use current router to grab selected session
            freqResponse = spectroGram.freqResponse;
            maxRange = [];
            for i = 1:height(session)
                singlePSD = session(i,:).(sprintf("PSD_%s",spgID)){1};
                t = session(i,:).(sprintf("t_%s",spgID)){1};
                f = session(i,:).(sprintf("f_%s",spgID));
                % visit each band/event
                tileSetFields = fieldnames(obj.bpFigure.panel1.tiles.Axes);    
                [poolDf, b] = poolBands(nexon.console.BASE.params.bands, spectroGram.f, singlePSD);                
                for j = 1:length(tileSetFields)
                    tileID = tileSetFields{j};
                    dfTrace = getBandTrace(b, poolDf, tileID, freqResponse);                    
                    line(t, squeeze(dfTrace),"Parent",obj.bpFigure.panel1.tiles.Axes.(tileID),"Color","#464e4f");
                    colorAx_green(obj.bpFigure.panel1.tiles.Axes.(tileID));
                end                
                maxRange = [maxRange; abs(max(dfTrace)-min(dfTrace))];
            end
            idxMaxRange = find(maxRange==max(maxRange));
            for j = 1:length(tileSetFields)
                tileID = tileSetFields{j};              
                plts = get(obj.bpFigure.panel1.tiles.Axes.(tileID),"Children");
                plts(idxMaxRange).Color = "#ffffff";               
            end
            drawnow
        end

        function deHorizon(obj, nexon, spectroGram)
            % remove all but the single, original, remaining trace
            tileSetFields = fieldnames(obj.bpFigure.panel1.tiles.Axes);            
            for j = 1:length(tileSetFields)
                tileID = tileSetFields{j};
                plts = get(obj.bpFigure.panel1.tiles.Axes.(tileID),"Children");
                for i = 1:size(plts,1)-1
                    delete(plts(1));
                    plts = get(obj.bpFigure.panel1.tiles.Axes.(tileID),"Children");
                end                
            end
        end
    end
end