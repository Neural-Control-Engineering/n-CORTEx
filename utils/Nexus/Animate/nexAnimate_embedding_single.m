function nexAnimate_embedding_single(nexObj, args)
    
    % CFG HEADER
    stride = args.stride; % default = 1    

    %% update axVal
    %% update marker
    len_trail=40;
    %% update clock/frame
    len_ax = length(nexObj.DF_postOp.ax.t);
    nexObj.frameNum = mod(nexObj.frameNum+stride, len_ax-len_trail)+1;
    % update clock
    % time = nexObj.frameNum ./ 500;
    % nexObj.nexon.console.BASE.controlPanel.clock = time;
    %% visualize
    nexObj.visualize();
end