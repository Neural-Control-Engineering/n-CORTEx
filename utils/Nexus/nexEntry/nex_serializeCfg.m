function serial = nex_serializeCfg(cfg)
% Recursively serialize any cfg tree (plain struct or nexObj_cfg) to a
% plain struct of primitives.  Function handles and handle objects are
% dropped — they are re-derived from modelID/classID at load time.
%
%   serial = nex_serializeCfg(mdlObj.cfg)
%   serial = nex_serializeCfg(nexObj.cfg)
%
% Works on any nesting depth: cfg.fitCfg.entryParams.stateDim, etc.
% nexObj_cfg (dynamicprops) and plain structs are treated identically.

    serial = struct();
    if isempty(cfg), return; end

    if isa(cfg, 'nexObj_cfg') || isa(cfg, 'dynamicprops')
        fields = properties(cfg);
    elseif isstruct(cfg)
        fields = fieldnames(cfg);
    else
        return
    end

    for i = 1:numel(fields)
        f   = fields{i};
        val = cfg.(f);
        if isa(val, 'function_handle')
            % dropped — re-derived by nex_generateCfgObj at construction
        elseif isa(val, 'nexObj_cfg')
            serial.(f) = nex_serializeCfg(val);
        elseif isstruct(val)
            serial.(f) = nex_serializeCfg(val);
        elseif isobject(val)
            % skip all other handle objects (Panel, Figure, selectionBus, etc.)
        elseif isstring(val) || ischar(val) || isnumeric(val) || islogical(val)
            serial.(f) = val;
        end
    end
end
