classdef nexObj_cfg < handle & dynamicprops
    methods
        function obj = nexObj_cfg(cfgIn)
            if nargin > 0
                % copy fields of input struct as dynamic properties
                fns = fieldnames(cfgIn);
                for i = 1:numel(fns)
                    addprop(obj, fns{i});
                    obj.(fns{i}) = cfgIn.(fns{i});
                end
            end
        end
    end
end
