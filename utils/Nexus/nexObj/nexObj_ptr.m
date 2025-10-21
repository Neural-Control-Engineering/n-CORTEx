classdef nexObj_ptr < handle & dynamicprops
    methods
        function nexPtr = nexObj_ptr(ptr)
            if nargin > 0
                % copy fields of input struct as dynamic properties
                fns = fieldnames(ptr);
                for i = 1:numel(fns)
                    addprop(nexPtr, fns{i});
                    nexPtr.(fns{i}) = ptr.(fns{i});
                end
            end
        end
    end
end
