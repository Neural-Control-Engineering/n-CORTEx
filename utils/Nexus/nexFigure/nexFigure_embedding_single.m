function nexFigure_embedding_single(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,500,1020,620],"Color",[0,0,0]);
    %% plot panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,600,580],"BackgroundColor",[0,0,0]);    
    %% Selection control (labeling)
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,200,440],"BackgroundColor",[0,0,0],"Scrollable","on");
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[815,5,200,440],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel2 = nexObj_listCfgPanel(nexObj.nexon, panel2, labelSelection,[]); % select one label (color bar = behavior, time, etc.)
    % nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, dimSelection, []); % select three dimensions
    %% Animation control
    panel1.ph = uipanel(nexObj.Figure.fh,"Position",[610,450,405,135],"BackgroundColor",[0,0,0],"Scrollable","on");
    cfgEntryChangedFcn = str2func("cfgEntryChanged_v2");
    uiFieldArgs.entryHeightScaler=5;
    aniArgs = nexObj.cfg.aniCfg.entryParams;
    nexObj.Figure.panel1 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.aniCfg, panel1, aniArgs, cfgEntryChangedFcn, uiFieldArgs);
    %% UI Control
    nexObj.Figure.playButton = uibutton("state","Parent",nexObj.Figure.fh,"Position",[5,590,25,25],"BackgroundColor",[0,0,0],"ValueChangedFcn",@(~,~)nexObj.startPlayer());    
    %% Build graphics
    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    Z = nexObj.DF_postOp.df;
    Y = nexObj.DF_postOp.ax.t;
    dim1=1;dim2=2;dim3=3;
    nexObj.Figure.panel0.tiles.graphics.canvas = scatter3(nexObj.Figure.panel0.tiles.ax,Z(:,dim1),Z(:,dim2),Z(:,dim3),10,Y','filled');    
    hold(nexObj.Figure.panel0.tiles.ax,"on");
    % Marker graphics
    len_trail = 40;
    t_start = nexObj.DF_postOp.ax.t(nexObj.frameNum);
    markerSlice = [nexObj.frameNum: nexObj.frameNum+(len_trail-1)];
    Z_marker = Z(markerSlice,:);
    % color mapping (markers)
    % Determine brightness based on one of the coordinates (say Z)
    % Normalize to [0, 1]
    % brightness = rescale(flip([1:len_trail],2), 0.3, 1.0);  % floor at 0.3 so nothing goes fully dark
    b = rescale(flip([1:len_trail],2),0,1);
    % Compute per-point RGB (each point gets a scaled green)
    % C = brightness' .* nexObj.nexon.settings.Colors.vyberGreen;  % Nx3 array
    % Interpolate between darkGray and greenRGB
    C = nexObj.nexon.settings.Colors.vyberGreen + b' .* (nexObj.nexon.settings.Colors.cyberGrey - nexObj.nexon.settings.Colors.vyberGreen);  % Nx3 matrix of RGB colors
    % graphic_0 = scatter3(nexObj.Figure.panel0.tiles.ax,Z_marker(:,dim1),Z_marker(:,dim2),Z_marker(:,dim3),65,[1:len_trail],"MarkerFaceColor",nexObj.nexon.settings.Colors.vyberGreen);
    graphic_0 = scatter3(nexObj.Figure.panel0.tiles.ax,Z_marker(:,dim1),Z_marker(:,dim2),Z_marker(:,dim3),100,C,'filled','MarkerEdgeColor','none');
    nexObj.Figure.panel0.tiles.graphics.tMarker0 = nexObj_tMarker(nexObj, graphic_0, nexObj.nexon.console.BASE.controlPanel, 0);
    % Color mapping
    colorAx_green(nexObj.Figure.panel0.tiles.ax);
    load(fullfile(nexObj.nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);    
end