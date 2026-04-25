function nex_restoreCfg(target, serial)
% Restore primitive cfg values from a serialized struct back into a live
% cfg tree (plain struct or nexObj_cfg).  Function handles already present
% in target are preserved — the serial never contains them.
%
%   nex_restoreCfg(mdlObj.cfg, state.cfg)
%   nex_restoreCfg(nexObj.cfg, state.cfg)
%
% Works at any nesting depth.  Unknown fields in serial are skipped
% (forward compatibility when state was saved from a newer config).

    if isempty(serial) || isempty(target), return; end

    fields = fieldnames(serial);
    for i = 1:numel(fields)
        f     = fields{i};
        saved = serial.(f);

        % Check whether the field exists in the live target
        if isa(target, 'nexObj_cfg') || isa(target, 'dynamicprops')
            exists = isprop(target, f);
        else
            exists = isfield(target, f);
        end
        if ~exists, continue; end

        live = target.(f);

        if isa(live, 'function_handle')
            % Never overwrite function handles — they are the live dispatch pointers
        elseif (isa(live, 'nexObj_cfg') || isstruct(live)) && isstruct(saved)
            nex_restoreCfg(live, saved);           % recurse
            if isstruct(target)
                target.(f) = live;                 % write back for plain structs
            end
        elseif isstring(saved) || ischar(saved) || isnumeric(saved) || islogical(saved)
            target.(f) = saved;
        end
    end
end
