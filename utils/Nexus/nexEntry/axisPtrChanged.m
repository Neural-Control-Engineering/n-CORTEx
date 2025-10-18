function axisPtrChanged(src, event, nexObj, nexPtr, axSel)
    axVal = src.Value;
    nexPtr.(axSel).value=axVal;
    % revisualize results
    nexObj.visualize();
end