function plotOScores(params, oscPRE, oscPOST, mPRE, mPOST, P, phase, event)        

    climMin = 0;
    climMax = 1;

    dash = struct;
    dash.fh = uifigure("Position",[25,1260,1150, 600],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    % colormap(dash.fh,CT);
    dash.panel1.ph1 = uipanel(dash.fh,"Position",[5,5,570,590],"BackgroundColor",[0,0,0]);
    t = tiledlayout(dash.panel1.ph1,1,4);
    dash.panel1.t = t;    
    tAx1 = nexttile(t);    
    dash.panel1.tAx1 = tAx1;
    dash.panel1.imgAx1 = imagesc(dash.panel1.tAx1,oscPRE.scores);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel1.tAx1.CLim = [climMin, climMax];
    dash.panel1.tAx1 = colorAx_green(dash.panel1.tAx1);
    title(dash.panel1.tAx1,"OScores","Color",[0.24,0.94,0.46])    
    tAx2 = nexttile(t);
    dash.panel1.tAx2 = tAx2;
    dash.panel1.imgAx2 = imagesc(dash.panel1.tAx2,oscPRE.powerMap);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel1.tAx2.CLim = [climMin, climMax];
    dash.panel1.tAx2 = colorAx_green(dash.panel1.tAx2);
    title(dash.panel1.tAx2,"Normalized PW","Color",[0.24,0.94,0.46])    
    tAx3 = nexttile(t);
    dash.panel1.tAx3 = tAx3;
    dash.panel1.imgAx3 = imagesc(tAx3,oscPRE.probabilityMap);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel1.tAx3.CLim = [climMin, climMax];
    dash.panel1.tAx3 = colorAx_green(dash.panel1.tAx3);
    title(dash.panel1.tAx3,"Probability Map","Color",[0.24,0.94,0.46])
    tAx4 = nexttile(t);
    dash.panel1.tAx4 = tAx4;
    % imgAx4 = imagesc(tAx,squeeze(mean(mPRE,1)));
    % imgAx4 = imagesc(tAx, squeeze(mPRE(:,:,1)))
    dash.panel1.maskIdx = 1;
    % mPRE_color = cMap2Regions(mPRE(:,:,1), params.regMap);
    % dash.imgAx4 = image(dash.tAx4, ((mPRE_color)))
    dash.panel1.imgAx4 = image(dash.panel1.tAx4, (mPRE(:,:,:,dash.panel1.maskIdx)))
    dash.panel1.tAx4 = colorAx_green(dash.panel1.tAx4);
    dash.panel1.mskData = mPRE;
    title(dash.panel1.t,sprintf("%s--%s--PRE",phase, event),"Color",[0.24,0.94,0.46]);
    % dash.Q = parallel.pool.DataQueue;
    % dash.Q.afterEach = @(~,~)updateMskIdx(dash);
    dash.panel1.mskNum = uieditfield(dash.panel1.ph1,"numeric","Position",[520,502,30,20],"Value",dash.panel1.maskIdx,"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46]);
    dash.panel1.b1 = uibutton(dash.panel1.ph1,"Position",[520,525,30,20],"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)flipMaskShow(dash,"panel1",1),"Text","+");    
    dash.panel1.b2 = uibutton(dash.panel1.ph1,"Position",[520,480,30,20],"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)flipMaskShow(dash,"panel1",-1),"Text","-");      

    dash.panel2.ph1 = uipanel(dash.fh,"Position",[578,5,570,590],"BackgroundColor",[0,0,0]);
    t = tiledlayout(dash.panel2.ph1,1,4);
    dash.panel2.t = t;    
    tAx1 = nexttile(t);    
    dash.panel2.tAx1 = tAx1;
    dash.panel2.imgAx1 = imagesc(dash.panel2.tAx1,oscPOST.scores);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel2.tAx1.CLim = [climMin, climMax];
    dash.panel2.tAx1 = colorAx_green(dash.panel2.tAx1);
    title(dash.panel2.tAx1,"OScores","Color",[0.24,0.94,0.46])
    tAx2 = nexttile(t);
    dash.panel2.tAx2 = tAx2;
    dash.panel2.imgAx2 = imagesc(dash.panel2.tAx2,oscPOST.powerMap);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel2.tAx.CLim = [climMin, climMax];
    dash.panel2.tAx2 = colorAx_green(dash.panel2.tAx2);
    title(dash.panel2.tAx2,"Normalized PW","Color",[0.24,0.94,0.46])    
    tAx3 = nexttile(t);
    dash.panel2.tAx3 = tAx3;
    dash.panel2.imgAx3 = imagesc(dash.panel2.tAx3,oscPOST.probabilityMap);
    % tAx.CLim = [0.0167, 0.8356];
    dash.panel2.tAx3.CLim = [climMin, climMax];
    dash.panel2.tAx3 = colorAx_green(dash.panel2.tAx3);
    title(dash.panel2.tAx3,"Probability Map","Color",[0.24,0.94,0.46])
    tAx4 = nexttile(t);
    dash.panel2.tAx4 = tAx4;
    % imgAx4 = imagesc(tAx,squeeze(mean(mPRE,1)));
    % imgAx4 = imagesc(tAx, squeeze(mPRE(:,:,1)))
    dash.panel2.maskIdx = 1;
    % mPRE_color = cMap2Regions(mPRE(:,:,1), params.regMap);
    % dash.imgAx4 = image(dash.tAx4, ((mPRE_color)))
    dash.panel2.imgAx4 = image(dash.panel2.tAx4, (mPOST(:,:,:,dash.panel2.maskIdx)))
    dash.panel2.tAx4 = colorAx_green(dash.panel2.tAx4);
    dash.panel2.mskData = mPOST;
    title(dash.panel2.t,sprintf("%s--%s--POST",phase, event),"Color",[0.24,0.94,0.46]);
    % dash.Q = parallel.pool.DataQueue;
    % dash.Q.afterEach = @(~,~)updateMskIdx(dash);
    dash.panel2.mskNum = uieditfield(dash.panel2.ph1,"numeric","Position",[520,502,30,20],"Value",dash.panel2.maskIdx,"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46]);
    dash.panel2.b1 = uibutton(dash.panel2.ph1,"Position",[520,525,30,20],"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)flipMaskShow(dash,"panel2",1),"Text","+");    
    dash.panel2.b2 = uibutton(dash.panel2.ph1,"Position",[520,480,30,20],"BackgroundColor",[0,0,0],"FontColor",[0.24,0.94,0.46],"ButtonPushedFcn",@(~,~)flipMaskShow(dash,"panel2",-1),"Text","-");      
  
  
end
