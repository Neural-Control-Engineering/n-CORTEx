function nexObj = nexPlot_slrt_timeCourse(nexon, nexObj)
    params    = nexon.console.BASE.params;
    DF        = nexObj.DF;

    nexObj.Figure.fh = uifigure("Position", [25, 560, 600, 250], "Color", [0,0,0]);
    load(fullfile(params.paths.repo_path, "Visualization/RealtimeVis/cmap-cyberGreen.mat"));

    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh, ...
        "Position", [5,5,280,240], "BackgroundColor", [0,0,0], "Scrollable", "on");
    panel2.ph = uipanel(nexObj.Figure.fh, ...
        "Position", [285,5,310,240], "BackgroundColor", [0,0,0], "Scrollable", "on");
    nexObj.Figure.panel2 = nexObj_listCfgPanel(nexObj.nexon, panel2, ...
        nexObj.eventAlignmentSelection, 1);

    nexObj.Figure.panel1.tiles.t        = tiledlayout(nexObj.Figure.panel1.ph, "flow", "TileSpacing", "tight");
    nexObj.Figure.panel1.tiles.graphics = struct;

    % Only build tiles for signals that have data
    if ~isfield(DF, 'df') || isempty(fieldnames(DF.df))
        return;
    end
    dfFields     = fieldnames(DF.df);
    activeFields = dfFields(cellfun(@(f) ~isempty(DF.df.(f)), dfFields));
    if isempty(activeFields)
        return;
    end

    for i = 1:numel(activeFields)
        dfField = activeFields{i};
        df_i    = DF.df.(dfField);
        t_df    = DF.ax.t.(dfField);
        tileID  = sprintf("tile_%s", dfField);
        axID    = sprintf("xMarkers_%s", dfField);

        ax_canvas = nexttile(nexObj.Figure.panel1.tiles.t);
        nexObj.Figure.panel1.tiles.Axes.(tileID) = ax_canvas;

        canvas_l = plot(ax_canvas, t_df, df_i, "Color", [1,1,1]);
        nexObj.Figure.panel1.tiles.graphics.(tileID) = canvas_l;
        hold(ax_canvas, "on");
        ax_canvas.YLabel.String = dfField;
        colorAx_green(ax_canvas);
        graphics = nex_generateEventMarkers(nexObj, ax_canvas);
        nexObj.Figure.panel1.tiles.graphics.(axID) = graphics;
        hold(ax_canvas, "off");

        tIdx    = nexObj.nexon.console.BASE.controlPanel.clock;
        graphic = xline(ax_canvas, tIdx, "Color", nexObj.nexon.settings.Colors.cyberGreen);
        nexObj.Figure.panel1.tiles.graphics.("tMarker") = ...
            nexObj_tMarker(nexObj, graphic, nexObj.nexon.console.BASE.controlPanel, 0);
    end
end
