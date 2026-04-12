function nex_buildCollectorViewPanel(nexObj, ph, H_panel)
% Build SRC / VW / CLR listboxes inside a collector View panel.
% Wires SRC with applySRC; all others with listCfgEntryChanged.
% ph      — parent uipanel handle (already created by caller)
% H_panel — height of ph (used to size listboxes)

    bus  = nexObj.collector.View;
    cyG  = nexObj.nexon.settings.Colors.cyberGreen;
    keys = string(fieldnames(bus.selKeys))';
    nK   = numel(keys);

    inner_w = ph.Position(3);
    w_list  = floor((inner_w - 5*(nK+1)) / nK);
    h_list  = H_panel - 50;

    for i = 1:nK
        k     = keys(i);
        x_pos = 5 + (i-1) * (w_list + 5);

        ph_k = uipanel(ph, "Title",char(k), "BackgroundColor",[0,0,0], ...
            "ForegroundColor",cyG, "Position",[x_pos, 5, w_list, H_panel-25]);

        vals = bus.selKeys.(char(k));
        nV   = max(1, numel(vals));

        if k == "SRC"
            cb = @(src,~) srcSelChanged(src, nexObj);
        else
            cb = @(src,~) listCfgEntryChanged(src, [], char(k), bus);
        end

        lb = uicontrol(ph_k, "Style","listbox", ...
            "Position",[2, 2, w_list-10, h_list], ...
            "String",vals, "Max",nV, "Value",1, ...
            "BackgroundColor","black", "ForegroundColor",cyG, ...
            "Callback",cb);
        bus.listBoxes.(char(k)) = lb;
    end
end

function srcSelChanged(src, nexObj)
    listCfgEntryChanged(src, [], 'SRC', nexObj.collector.View);
    keys   = nexObj.collector.View.selKeys.SRC;
    srcKey = keys(src.Value);
    nexObj.applySRC(srcKey);
end
