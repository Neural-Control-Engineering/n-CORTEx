function nexAnimate_pixelGram(nexObj, args)

        % CFG HEADER
        stride = args.stride; % default = 1        

        %% update axVal
        axSel = convertCharsToStrings(nexObj.Figure.axSelDropDown.Value);
        axVal_prev = nexObj.DF_postOp.ptr.(axSel).value;
        len_ax = length(nexObj.DF_postOp.ax.(axSel));
        axVal = axVal_prev + stride;
        axVal = mod(axVal,len_ax)+1;
        % update df slice / axis control / ptr
        nexObj.DF_postOp = nex_setAxisPointer_v2(nexObj.DF_postOp, axSel, axVal);      
        % update uiSpinner and run callback to visualize result
        nexObj.Figure.panel5.editFields.t.uiField.Value=axVal;
        % nexObj.Figure.panel5.editFields.t.uiField.ValueChangedFcn;       
        % notify(nexObj.Figure.panel5.editFields.t.uiField,"ValueChanged");       
        % update clock
        time = nexObj.DF_postOp.ptr.t.value / nexObj.Partners.npxTC.UserData.Fs - nexObj.Partners.npxTC.UserData.preBufferLen;
        % nexObj.nexon.console.BASE.controlPanel.clock = time;
        % visualize
        nexObj.visualize();
end